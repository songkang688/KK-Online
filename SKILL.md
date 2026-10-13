---
name: KK Online
description: >-
  Use whenever shipping a Git app or static site online for KK: full end-to-end
  SOP (Railway/Render/HF/UPMA), Docker+PORT, Gradio vs rebuild-as-web, blog
  wiring, smoke/redeploy/debug, templates/scripts, and face-dehighlight history.
  Prefer this over ad-hoc deploy notes.
---
# KK Online — 从 Git 到公网的完整发布手册

本技能是 **KK 项目上线的标准作业程序（SOP）**。流程可复用到任意新仓库；文末「历史快照」记录已做过的项目与账号/URL，作记忆用，**新项目不要把旧 URL 当死命令照抄**。

执行本技能时：按阶段推进，每阶段结束留下笔记（路径、URL、project/service id）；密钥永不写入仓库/镜像/技能正文。

**配套仓库：** GitHub `songkang688/KK-Online`（box 草稿 `/workspace/KK-Online/`）提供 templates / scripts / checklists / docs，与本技能正文一一对应。见 §16。

---

## 0. 何时启用

在下列任一情况 **立刻 Read 并遵循本技能**：

- 用户说：发布、上线、部署、挂公网、免费托管、接博客「进入官网」、换前端再发一版
- 新 Git 项目要从本地/仓库走到可点击的 HTTPS
- 已有线上服务要迭代、修 bug、换 UI 形态（Gradio ↔ 自定义 Web）、重新接线博客
- 用户提到 Railway / Render / Hugging Face Spaces / UPMA / Gradio share / Cloudflare tunnel 与「上线」相关

**配套技能（按需再 Read）：**

| 场景 | 技能 |
|------|------|
| Railway CLI / MCP / 登录 / 域名 | `use-railway` |
| HF CLI / Spaces | `hf-cli`、`huggingface-spaces` |
| 推 GitHub / PR | `code-changes` |
| 无连接器登录 | `no-connector-fallback`、`sign-in` |

**用户说「发布 / 上线」时：** 直接按 §17「一键推进」从 Turn 0 顺序执行，不要跳步。

---

## 1. 总原则（每次都遵守）

1. **先定「上线形态」再选型平台**（见 §3），不要一上来就建 Space 或乱开隧道。
2. **能 Docker + 读 `PORT` → 默认 Railway**；纯静态 → UPMA；HF 仅账号允许且用户明确要时用。
3. **一种产品形态 = 一个 Railway project/service**。Gradio 与自定义 Web 并存时分项目，**禁止用新形态覆盖仍在用的旧生产**（见 §19）。
4. **部署目录与开发树分离**（如 `high` 源码 vs `high-deploy` / `high-webui`），避免污染源仓；需要进 Git 时单独提交，且 **不提交 token**。
5. 应用必须：`0.0.0.0` + `int(os.environ.get("PORT", "7860"))`（或等价）。
6. **出网受限环境**（沙箱 DNS/UDP 被拦）不要死磕 Gradio `share=True` / Cloudflare tunnel → 改 PaaS。
7. 上线后必做冒烟（§9）；接线博客后必硬刷新验证。
8. 每完成一阶段：更新 box 笔记 + agent 记忆（URL、项目名、与旧服务关系）；**永不把密钥写入技能或公开笔记**。
9. 对用户沟通默认中文（简体）；技术标识符保留英文。
10. **阶段门禁未过，不得进入下一阶段**（见 §18）。
11. 优先复用 `KK-Online` 仓库里的 templates/scripts，而不是每次手写 Dockerfile。

---

## 2. 端到端总览（一张图）

```text
[Git 源码 / 本机副本]
        │
        ▼
 ① 摸清产物：入口、依赖、模型、GPU?、现有 UI
        │  Gate①: 形态候选清楚；入口/依赖已知
        ▼
 ② 选定上线形态 A–F（§3）+ 平台
        │  Gate②: 用户偏好已对齐；写进笔记
        ▼
        ├─ 计算型 Web ──► ③ 打部署包（Dockerfile + PORT + 配置）
        │                      │  Gate③: 本地/镜像可启或配置齐全
        │                      ▼
        │                 ④ 平台账号就绪（Railway 优先）
        │                      │  Gate④: whoami / 登录成功
        │                      ▼
        │                 ⑤ railway up / Render /（可选）HF Space
        │                      │  Gate⑤: Deployment SUCCESS
        │                      ▼
        │                 ⑥ Generate Domain → 公网 HTTPS
        │                      │  Gate⑥: HTTPS 可 curl
        │                      ▼
        │                 ⑦ 冒烟：/ 、/health、核心 API、UI
        │                         Gate⑦: 冒烟表全绿
        │
        └─ 静态站/博客/游戏 ──► ③' 改 HTML/打 dist → UPMA zip merge
                                       │  Gate③': zip 路径正确、无密钥
                                       ▼
                                  ⑦' 预览 URL 核对
        │
        ▼
 ⑧ 博客「进入官网」接线（新标签全屏 或 iframe）
        │  Gate⑧: 主入口可点开正确目标
        ▼
 ⑨ 笔记 + 记忆 +（可选）更新本技能历史快照
        │  Gate⑨: 笔记含 URL/ids
        ▼
 ⑩ 迭代：修 bug → 同目录 redeploy → 再冒烟
           （回滚规则见 §19）
```

---

## 3. 上线形态决策（先做这一步）

| 代号 | 源码现状 | 上线做法 | 平台 |
|------|----------|----------|------|
| **A** | 已有 Gradio / Streamlit / 同类 Web UI | 容器直接跑入口（`app.py` 等） | Railway（首选）/ Render |
| **B** | 仅桌面 GUI（PyQt / Qt / Electron 桌面壳等） | **重建为 Web**：静态 SPA + 后端 API；**不要**试图 iframe 桌面程序 | **新** Railway project |
| **C** | 已有 Web 前端 + API | 同仓或分服务打包；注意 CORS、静态挂载路径 | Railway |
| **D** | 静态博客 / 项目介绍页 / 小游戏 dist | 改文件或 `npm run build` → **UPMA 增量 zip merge** | UPMA |
| **E** | 临时给人看一眼 | Gradio `share=True` 或本机隧道 | 仅临时；生产勿用 |
| **F** | 想用 HF Spaces | 确认账号可建 Gradio/Docker Space + 有 write token | HF；否则回 A |

**用户口头偏好覆盖默认值。** 若用户明确「全屏、非嵌入、非 Gradio、带下一张」→ 走 **B**，即使已有 Gradio 线上版也保留旧服务作次要入口。

问清（或从仓库自查）并记笔记：

- 入口文件与启动命令
- `requirements.txt` / package 管理器
- 模型与大文件路径（是否必须进镜像）
- 是否需要 GPU（多数 CPU MediaPipe 类不需要）
- 健康检查路径（`/` 或 `/health`）
- 是否已有公网 URL / 博客入口文案
- 是否已有旧生产服务（若有 → 新形态必须新 project，见 §19）

---

## 4. 平台与资源详解

### 4.1 Railway（默认推荐）

**适合：** Gradio、FastAPI、自定义 SPA+API、任意 Dockerfile Web 服务。

**资源模型：** Workspace → Project → Environment（如 production）→ Service → Deployment。

**拿到公网 URL：** Dashboard → 服务 → **Settings → Networking → Generate Domain** → `https://<name>-production.up.railway.app`。

**CLI 典型流程（box 或本机）：**

```bash
# 环境（box 上常已安装）— 也可用仓库 scripts/railway-up.sh
source "$HOME/.railway/env" 2>/dev/null || true
export PATH="$HOME/.railway/bin:$PATH"
# 若使用 Railway agent/skill 会话标记（按 use-railway 当前要求设置）：
# export RAILWAY_CALLER=skill:use-railway@…
# export RAILWAY_AGENT_SESSION=railway-skill-<project>-1

railway whoami          # 未登录则 railway login（浏览器/设备码）
cd /path/to/deploy-dir
railway init            # 或首次 railway up 引导建项目
# 链接已有项目时可用：railway link --project <id> --environment <id> --service <id>
# 更推荐命令行显式传 --project / --environment / --service，少改全局 link 状态

railway up -y --detach  # 上传当前目录构建部署
railway status
railway logs            # 失败时看 build / runtime
railway domain          # 若 CLI 支持列/生成域名；否则用 Dashboard Generate Domain
```

**配置文件 `railway.toml`：** 见仓库 `templates/railway.toml`（与下方相同）。

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 5
```

健康检查路径若应用提供 `/health`，可改为 `/health`；超时要够（模型预加载可能 >60s）。

**MCP：** Railway 插件 MCP 若 `needsAuth`，走 OAuth；也可用已登录 CLI。细操遵循 `use-railway`。

**计费注意：** Hobby/试用有额度；闲置可能冷启动变慢。首次 build 常 5–15 分钟（pip + 本地模型拷贝）。

**多形态 / 多项目规则（硬规则）：**

- 已有 `high-deploy`（Gradio）时，新做自定义 Web → **新建** `high-webui` project
- **禁止** 在仍被博客/用户使用的旧 service 上 `railway up` 上传另一种形态的目录
- 两边 URL 都保留；博客主入口指向当前主推，次要入口指向旧形态

### 4.2 Render（备选）

1. https://render.com 注册（可 GitHub）。
2. New → Blueprint（`templates/render.yaml`）或 Web Service → Runtime **Docker** → Dockerfile path `./Dockerfile` → Free。
3. 平台注入 `PORT`。
4. URL 形如 `https://<name>.onrender.com`。
5. **免费档约 15 分钟无流量休眠**；冷启动可达 1–2+ 分钟。不适合当「官网主入口」除非用户接受。

```yaml
services:
  - type: web
    name: my-app
    runtime: docker
    plan: free
    dockerfilePath: ./Dockerfile
    healthCheckPath: /
    envVars:
      - key: PORT
        value: "7860"
```

**`Procfile`（非 Docker 时偶用）：** `web: python app.py`（见 `templates/Procfile`）。

### 4.3 Hugging Face Spaces

- **免费账号常无法创建 Gradio Space（需 PRO 或政策允许）**；先 `hf auth whoami` / 查配额再承诺。
- 布局：Space 根 ≈ 应用根；README YAML：`sdk: gradio`，`app_file: app.py`（或 Docker SDK）。
- 公网：`https://huggingface.co/spaces/<user>/<space>`，嵌入 `https://<user>-<space>.hf.space`。
- 无 `HF_TOKEN` / 未登录时 **不要假装能从沙箱创建 Space**；请用户提供 write token 或自行在网页创建后把 URL 交回来接线。
- CPU MediaPipe 类优先要 **CPU** Space，不必强上 ZeroGPU。
- 失败则立即回退形态 A（Railway），不要卡在 HF。

### 4.4 UPMA（静态博客 / 游戏 / 增量页）

**适合：** 博客站、项目介绍页、小游戏 `dist`、iframe 壳页面。

**做法：**

1. 在本地博客树（如 `blog-site/`）改文件。
2. **增量 zip**：只包含变更相对路径（保持站点内相对路径）。用 `scripts/make-upma-zip.sh`。
3. 上传到 UPMA 对应 project 做 **merge** 部署（不要无故整站覆盖）。
4. 打开预览/生产 URL 核对链接、资源 404、移动端。

**按钮接线惯例：**

- 主 CTA「进入官网」→ 当前主推的全屏 Web（`target="_blank"` `rel="noopener"`）
- 次要：「Gradio 版」→ 旧 Gradio URL
- 第三：「嵌入页」→ 站内 `/demos/....html` iframe

### 4.5 Gradio share / 隧道（仅临时）

- `share=True` 依赖本机可达 Gradio FRP（如 `frp.gradio.live`）。沙箱若 DNS 到黑洞 IP（如 `198.18.0.1`）或 TCP 7000 超时 → **失败，改 PaaS**。
- Cloudflare tunnel 等若 UDP 被拦 → 同样放弃。
- 链接会过期；**禁止当作生产官网**。

---

## 5. 阶段 ①–②：摸清产物与建部署目录

1. Clone 或定位源码：`git clone` / 已有 `/workspace/<repo>`。
2. 读 README、入口、`requirements.txt`、是否有现成 Dockerfile。
3. 选定形态 A–F；若已有旧生产，确认 §19 不覆盖规则。
4. 创建部署目录（示例命名）：

```bash
# 形态 A：Gradio 等
cp -a /workspace/<src> /workspace/<name>-deploy
# 形态 B：自定义 Web
mkdir -p /workspace/<name>-webui
# 拷算法包、models、configs、data；新建 web_server.py + static/
```

5. 从 `KK-Online/templates/` 拷贝：`Dockerfile.python-cv`→`Dockerfile`、`railway.toml`、`dockerignore`→`.dockerignore`、（可选）`render.yaml`、`Procfile`。
6. 按形态改 COPY/CMD；写 `DEPLOY.md` 或 `/workspace/<name>-notes.md`。

**Gate①→②：** 入口、依赖、模型路径、形态代号、是否新建 project 四字写进笔记。

---

## 6. 阶段 ③：应用改造清单（PaaS 必改）

### 6.1 端口与监听

**Gradio**（完整片段见 `templates/gradio_port_snippet.py`）：

```python
port = int(os.environ.get("PORT", "7860"))
app.launch(
    server_name="0.0.0.0",
    server_port=port,
    # share=False  # 生产容器不要依赖 share
)
```

**FastAPI/Uvicorn**（见 `templates/fastapi_port_snippet.py`）：

```python
HOST = "0.0.0.0"
PORT = int(os.environ.get("PORT", "7860"))
uvicorn.run(app, host=HOST, port=PORT)
```

### 6.2 路径与资源

- 样本目录用相对仓库路径（如 `data/`），勿写死开发者本机绝对路径。
- 模型文件（如 `models/face_landmarker.task`）必须 COPY 进镜像或启动时可下载（下载需网络与许可）。
- 可写目录：`runtime_outputs/` 等在 Dockerfile 里 `mkdir`。

### 6.3 CORS（自定义前端或跨域博客调 API 时）

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 或收紧到博客域名
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

同源方案更优：静态由同一 FastAPI `StaticFiles` mount，减少 CORS 面。

### 6.4 健康检查

建议提供：

- `GET /` → 页面或 200
- `GET /health` → `{"ok": true, ...}`（含 UI 类型、模型是否就绪）

`railway.toml` 的 `healthcheckPath` 与之一致；模型预加载慢则加大 `healthcheckTimeout`。

### 6.5 `.dockerignore`

见 `templates/dockerignore`。**禁止：** `.env`、token、私钥、本机绝对路径配置。

**Gate③：** Dockerfile + PORT 片段 + .dockerignore 就位；无密钥进上下文。可选本地 `PORT=7862 python …` 或 docker build 冒烟。

---

## 7. Dockerfile 模板（Python + OpenCV/MediaPipe 类）

完整可拷文件：`templates/Dockerfile.python-cv`。

```dockerfile
FROM python:3.11-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=7860 \
    GRADIO_SERVER_NAME=0.0.0.0

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    libgomp1 \
    libegl1 \
    libgles2 \
    libglvnd0 \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# 按形态 COPY：Gradio 用 app.py；WebUI 用 web_server.py + static/
COPY app.py .
COPY highlight_removal ./highlight_removal
COPY configs ./configs
COPY models ./models
COPY data ./data
# COPY assets ./assets
# COPY web_server.py cli_process.py ./
# COPY static ./static

RUN mkdir -p /app/runtime_outputs

EXPOSE 7860
CMD ["python", "app.py"]
# WebUI: CMD ["python", "web_server.py"]
```

**Node/静态：** 用多阶段 build 出 `dist`，或只把 `dist` 交给 UPMA（不一定上 Railway）。

---

## 8. 阶段 ④–⑥：账号、首次部署、域名

### 8.1 Railway 首次

1. 用户注册/登录 https://railway.app（可用 GitHub）。
2. Agent：`railway login`（浏览器授权）→ `whoami` 确认邮箱。**Gate④。**
3. **确认目标 project**：新形态 → `railway init` 新项目；迭代旧形态 → link 到**正确**的旧 project（核对 id）。
4. `cd` 部署目录 → `scripts/railway-up.sh` 或 `railway up -y --detach`。
5. 等 Deployment **SUCCESS**；失败则 `railway logs` / Dashboard build log：缺系统库、缺模型、PORT 绑错、健康检查杀进程是常见因。**Gate⑤。**
6. **Generate Domain**；把 HTTPS URL 记入笔记。**Gate⑥：** `curl -I https://…` 非连接失败。
7. 记下：Project 名与 id、Service 名与 id、Environment id、Dashboard 链接、CLI 账号邮箱。

### 8.2 从 GitHub 部署（可选）

- 先把 Dockerfile / railway.toml / PORT 补丁推进用户仓库（**经用户确认再 push**）。
- Railway「New Project → Deploy from GitHub」选仓库与根目录。

### 8.3 本地/容器冒烟（可选，部署前）

```bash
cd /workspace/<deploy>
PORT=7862 python app.py   # 注意勿占用已有服务端口（7860/7861）
# 或
docker build -t <name> .
docker run --rm -p 7862:7860 -e PORT=7860 <name>
```

---

## 9. 阶段 ⑦：冒烟清单（上线门禁）

对公网 URL 执行（`scripts/smoke-http.sh` 或浏览器）：

| 检查 | 期望 |
|------|------|
| `GET /` | 200；Gradio 或自定义 HTML |
| `GET /health`（若有） | `ok: true`；模型就绪 |
| 核心处理 API | 正确状态码与 Content-Type（如 `image/png`）；体积合理 |
| UI 主路径 | 上传/选样例 → 处理 → 出图/下载；模式切换、上一张/下一张（若有） |
| 缓存 | 改过 CSS/JS 后 **Cmd/Ctrl+Shift+R** |
| 日志 | 无持续崩溃重启 |

**自定义 Web 额外：** 看响应头/页面 meta 是否带耗时；若耗时已出但遮罩不消失 → 按 §11 查前端，不是后端没跑完。

**Gate⑦：** 上表全部通过才可向用户宣告「已上线」并进入博客接线。

---

## 10. 阶段 ⑧：博客 / 官网接线

1. 决定主入口形态：
   - **全屏新标签**（推荐给完整 Web UI）：`<a href="https://….up.railway.app" target="_blank" rel="noopener">进入官网</a>`
   - **站内嵌入**：`demos/xxx-official.html` 内 iframe `src` = 公网 URL；无 URL 时显示「后端待上线」占位。
2. 项目页可同时保留：主链接 +「Gradio 版」+「嵌入页」。
3. UPMA：`scripts/make-upma-zip.sh` → merge → 打开 `https://….upma.site/...` 验证。
4. 薄演示页若另有 `DEHIGHLIGHT_API` 之类环境变量，与「完整官网」分开文档化，勿混为一谈。

**Gate⑧：** 主 CTA 打开的是当前主推 HTTPS；次要入口仍指向旧服务（若保留）。

---

## 11. 阶段 ⑩：迭代、排障、Redeploy

### 11.1 Redeploy

```bash
# 推荐：bash /workspace/KK-Online/scripts/railway-up.sh /workspace/<deploy-dir>
source "$HOME/.railway/env" 2>/dev/null || true
export PATH="$HOME/.railway/bin:$PATH"
cd /workspace/<deploy-dir>
# 再次确认 link 的 project id 就是要更新的那个（§19）
railway up -y --detach
# 等 SUCCESS → 再跑 §9 冒烟
```

### 11.2 排障树

```text
页面打不开
  → Domain 是否生成？Deployment 是否 SUCCESS？健康检查是否失败杀进程？
处理按钮无响应 / 5xx
  → runtime logs；模型路径；内存；请求体大小
「一直处理中」但已有耗时/结果 meta
  → 后端往往已成功：查 CSS（.busy{display:grid} 覆盖 [hidden]）
  → 修复：见 templates/busy_hidden_fix.css
       .busy[hidden], .progress-track[hidden] { display: none !important; }
  → JS finally 里 setAttribute("hidden","")；等结果图 onload 再关遮罩
  → 用户硬刷新清缓存
CORS 报错
  → API 中间件 allow_origins；或改同源（静态由同一 FastAPI mount）
HF / share 失败
  → 停；改 Railway
Build 失败缺 libGL
  → Dockerfile 补 §7 系统库
部署打到错误项目
  → 立刻停；按 §19 回滚/纠正 link；不要在错误 service 上继续 up
```

更完整排障文：仓库 `docs/TROUBLESHOOTING.md`。

### 11.3 前端重建（形态 B）要点

- 对照桌面 UI（如 PyQt `app_simple`）列出：模式、上传、样例、上一张/下一张、处理、下载、进度/遮罩。
- `static/index.html` + `app.css` + `app.js`；API 如 `POST /api/dehighlight` 返回图片字节。
- 进度与 `hidden` 属性、`display` 布局类不要互相打架（见上）。
- 样例图走 `/samples/...`；处理勿阻塞健康检查过久（可启动时预加载模型）。

---

## 12. 文档与记忆（每次上线后）

在 box 写/更新：`/workspace/<name>-notes.md` 或 `*-railway-live.md`，至少含：

- 公网 URL
- Railway project/service/environment id + Dashboard 链接
- 部署目录路径、入口命令
- 与旧服务关系（保留 / 废弃 / 次要入口）
- 博客接线状态与 UPMA project id
- CLI 账号邮箱（非密码）
- 最近一次冒烟结果与日期（用户时区 Asia/Singapore）

并用 `UpdateMemory` 写短事实（log）：主 URL、项目名、形态。重大流程变更时 **回写本技能「历史快照」** 与仓库 `docs/HISTORY.md`。

**Gate⑨：** 笔记可被下一任助手接手，无需再问用户要 URL。

---

## 13. 完整检查清单（复制到任务里勾）

也见仓库 `checklists/SHIP.md`。

**准备**

- [ ] 源码定位；形态 A–F 已选
- [ ] 部署目录与源码分离
- [ ] PORT + 0.0.0.0；路径相对化
- [ ] Dockerfile + 系统库 + .dockerignore（无密钥）
- [ ] railway.toml / render.yaml 健康检查合理
- [ ] 已确认不会覆盖旧生产（§19）

**平台**

- [ ] 账号已登录（Railway/HF）
- [ ] 新形态使用新 project（未覆盖旧生产）
- [ ] Deployment SUCCESS
- [ ] Domain 已生成

**质量**

- [ ] `/` 与 `/health`（若有）通过
- [ ] 核心 API/UI 主路径通过
- [ ] 硬刷新验证 CSS/JS
- [ ] 博客主/次入口与 UPMA 已更新
- [ ] 笔记 + 记忆已写

---

## 14. 历史快照（KK 实战记忆，非通用死命令）

> 截至 **2026-10-13**（Asia/Singapore）。新项目替换名称与 URL；下列用于续作与排障。同步维护：`docs/HISTORY.md`。

### 14.1 人物与账号

- 用户：Barbara；沟通中文简体
- GitHub：`songkang688`
- Hugging Face：`kangkang6497`（Gradio Space 免费档可能不可用）
- Railway CLI 账号曾用：`1621859371@qq.com`

### 14.2 核心仓库：人脸面部去高光

- GitHub：`songkang688/high`
- 技术：MediaPipe FaceLandmarker + OpenCV；模式含「常用 / 高保真 / 最高质量」等
- box 源码：`/workspace/high`
- 另有薄 API：`api_server` 本地端口习惯 **7861**（博客可选 `DEHIGHLIGHT_API`）；与 Gradio **7860** 勿冲突
- 本手册仓库：`songkang688/KK-Online`

### 14.3 线上服务 A — Gradio 全量 UI

- 目录：`/workspace/high-deploy`（含 `app.py`、Dockerfile、railway.toml、render.yaml、DEPLOY.md）
- Railway **project `high-deploy`**
  - Project ID：`a67ee9b9-c530-44a6-b9b0-c1fedc35478c`
  - 公网：https://high-deploy-production.up.railway.app
  - Dashboard：https://railway.com/project/a67ee9b9-c530-44a6-b9b0-c1fedc35478c
- **不要被 webui 部署覆盖**

### 14.4 线上服务 B — 自定义全屏 Web（PyQt 风格重建）

- 目录：`/workspace/high-webui`
  - `web_server.py`：FastAPI；`/api/dehighlight`、`/process`、`/health`、静态与 samples
  - `static/`：`index.html`、`app.css`、`app.js`
  - `cli_process.py`、`highlight_removal/`、`models/`、`configs/`、`data/`
- Railway **project `high-webui`**
  - Project ID：`a3cd50c2-0ec5-490b-bbc2-f2b5312fa7a9`
  - Service ID：`6e3612d6-2d82-4e88-9ca2-1438f18d214f`
  - Environment production：`394d8875-cd76-415f-910d-d32204ffc389`
  - 公网：https://high-webui-production.up.railway.app
  - Dashboard：https://railway.com/project/a3cd50c2-0ec5-490b-bbc2-f2b5312fa7a9/service/6e3612d6-2d82-4e88-9ca2-1438f18d214f
- 用户选择：**rebuild-pyqt-as-web**；全屏新标签，非博客 iframe 嵌 Gradio
- 冒烟（2026-10-13 SGT）：`GET /` 200；`GET /health` ok；`POST /api/dehighlight` → PNG

### 14.5 博客与 UPMA

- 博客：https://astro-aguc.upma.site
- 本地树：`/workspace/blog-site/`
  - 项目页：`projects/face-dehighlight.html`（「进入官网」→ webui；次要 Gradio；第三嵌入页）
  - 嵌入壳：`demos/face-dehighlight-official.html`
- UPMA project id：`310dacff-fa40-4db7-b452-86656a742fb4`
- 增量 zip 例：`/workspace/blog-webui-wire.zip`（含 `projects/face-dehighlight.html`）

### 14.6 其它已上线相关

- 小游戏包（如 yiduo-yixing2）经 UPMA 静态发布；关卡解锁等属游戏逻辑，与 PaaS Docker 分流处理
- HF Gradio Space：曾因免费档/无 token 未作为主路径；免费替代 = Railway Docker
- Gradio share 失败日志特征：`dial tcp 198.18.0.1:7000: i/o timeout`（`frp.gradio.live` 被 sinkhole）

### 14.7 已踩坑（务必写进排障习惯）

1. **Gradio share / Cloudflare tunnel** 在出网受限 box 上失败 → 改 Railway。
2. **HF 免费无法建 Gradio Space** → 勿卡在 HF。
3. **「处理中…」假死**：API 已返回 PNG 且 meta 有耗时；根因 `.busy { display:grid }` 盖过 HTML `hidden`。修复：`templates/busy_hidden_fix.css` + JS `finally` 强制 hidden + 等图片 load。
4. **端口占用**：本地 7860/7861 并存时用 7862 做冒烟。
5. **多产品同仓**：分 `high-deploy` / `high-webui` 两项目，博客双入口。

### 14.8 Redeploy 速记（webui）

```bash
source "$HOME/.railway/env"
export PATH="$HOME/.railway/bin:$PATH"
cd /workspace/high-webui
railway up -y --detach
```

冒烟：`GET /`、`GET /health`、`POST /api/dehighlight` → `image/png`。

---

## 15. 新项目怎么套用（最短路径）

1. Read 本技能 §1–§3 → 定形态；或直接走 §17。
2. 复制 `KK-Online/templates/` + §6–§7 打部署包。
3. §8 Railway 上线 → §9 冒烟（`scripts/smoke-http.sh`）。
4. 若有博客：§10 UPMA 接线（`scripts/make-upma-zip.sh`）。
5. §12 写笔记；把新 URL 追加到 §14 / `docs/HISTORY.md`。
6. 出问题走 §11；平台细节 Recurse 到 `use-railway` / HF skills。

**完成定义：** 用户能从博客或分享的 HTTPS 链接打开主功能，冒烟通过，旧服务按策略保留或降级为次要入口，笔记可接手下一任助手。

---

## 16. 仓库配套（songkang688/KK-Online）

本技能的「可执行附件」在 GitHub 仓库 **KK Online**（本地 `/workspace/KK-Online/`）。Grok Bot 技能 id：`kk-online`。

| 路径 | 用途 |
|------|------|
| `README.md` | 项目简介、快速开始、与技能关系 |
| `SKILL.md` | 与本技能同步的完整 SOP |
| `docs/FLOW.md` | 端到端流程详解 |
| `docs/PLATFORMS.md` | Railway / Render / HF / UPMA |
| `docs/TROUBLESHOOTING.md` | 排障树 |
| `docs/HISTORY.md` | 历史快照（去高光等） |
| `checklists/SHIP.md` | 上线检查清单 |
| `templates/Dockerfile.python-cv` | Python+OpenCV/MediaPipe Dockerfile |
| `templates/railway.toml` | Railway 构建/健康检查 |
| `templates/render.yaml` | Render Blueprint |
| `templates/Procfile` | 非 Docker web 进程 |
| `templates/dockerignore` | 拷为 `.dockerignore` |
| `templates/fastapi_port_snippet.py` | FastAPI PORT/CORS |
| `templates/gradio_port_snippet.py` | Gradio PORT |
| `templates/busy_hidden_fix.css` | 遮罩 hidden 修复 |
| `scripts/smoke-http.sh` | curl `/` `/health` 可选 POST |
| `scripts/railway-up.sh` | source env + `railway up -y --detach` |
| `scripts/make-upma-zip.sh` | 增量 zip（相对路径） |

**用法：** 新项目时 `cp` templates 到部署目录并改 COPY/CMD；上线用 scripts；勾 checklists；细节以本技能 §0–§19 为准。

---

## 17. 一键推进（用户说「发布/上线」时按 Turn 执行）

Agent **不得跳步**。每 Turn 结束对照 §18 Gate；未过 Gate 则停在本阶段排障，并向用户报告阻塞点。

| Turn | 动作 | 产出 | 进入下一 Turn 前必须满足 |
|------|------|------|--------------------------|
| **0** | Read 本技能；扫源码 README/入口/依赖/模型；问清或推断形态 A–F | 笔记草稿：入口、依赖、GPU?、旧 URL | Gate① |
| **1** | 与用户偏好对齐（全屏/Gradio/静态）；定平台；若已有旧生产 → 计划**新** project 名 | 形态+平台+「是否新建 project」写入笔记 | Gate② |
| **2** | 建部署目录；拷 `templates/*`；改 PORT/Dockerfile/CMD；无密钥 | 可 `ls` 的部署树 | Gate③ |
| **3** | `railway whoami`（或 Render/HF 登录）；未登录则走 `use-railway`/`sign-in` | 账号邮箱已知 | Gate④ |
| **4** | `railway init`（新）或 link **正确** ids；`railway-up.sh` / `railway up -y --detach` | Deployment 进行中 | — |
| **5** | 等 SUCCESS；失败则 logs + §11；成功则 Generate Domain | HTTPS URL | Gate⑤ + Gate⑥ |
| **6** | `smoke-http.sh <URL>` + 浏览器主路径 | 冒烟结果表 | Gate⑦ |
| **7** | （若有博客）改 CTA/iframe；`make-upma-zip.sh`；UPMA merge；硬刷新验证 | 博客主入口正确 | Gate⑧ |
| **8** | 写 `/workspace/<name>-notes.md`；UpdateMemory；必要时更新 §14 / HISTORY.md | 可交接笔记 | Gate⑨ |
| **9** | 向用户交付：主 URL、次要 URL、博客链接、redeploy 命令 | 完成定义满足 | — |

**迭代（已上线修 bug）：** Turn 2（改代码）→ 确认 project id（§19）→ Turn 4–6 → 必要时 Turn 7–8。

**仅静态/UPMA：** Turn 0–1 定形态 D → 改文件 → `make-upma-zip.sh` → merge → Turn 6' 预览核对 → Turn 8。

---

## 18. 阶段门禁（Gate）

| Gate | 必须为真 | 未满足时 |
|------|----------|----------|
| **①** | 入口文件、依赖清单、模型/大文件策略已知；至少列出候选形态 | 继续读仓库；缺 HF/GPU 信息可标「待确认」但不得瞎选 F |
| **②** | 形态 A–F 已定；平台已定；「新建 vs 复用 project」已定并与用户偏好一致 | 用一句话向用户确认偏好后再继续 |
| **③** | 部署目录存在；Dockerfile + PORT/`0.0.0.0` + .dockerignore；无 `.env`/token 在目录内 | 补模板；`rg` 扫密钥关键字 |
| **④** | `railway whoami`（或等价）成功 | login；不要用无效 token 硬推 |
| **⑤** | 目标 project/service 上最新 Deployment = SUCCESS | 读 logs；修 Dockerfile/健康检查；禁止换到「随便另一个」service 蒙混 |
| **⑥** | 公网 HTTPS 已生成且 `curl -sI` 有响应（允许短暂冷启动重试） | Dashboard Generate Domain；查 networking |
| **⑦** | §9 冒烟表全绿（或用户书面接受已知降级） | 按 §11 排障；前端假死不要误判为未部署 |
| **⑧** | 博客主 CTA（若适用）指向当前主推 URL；硬刷新后可见 | 修 HTML；重打 zip merge |
| **⑨** | 笔记含 URL + project/service/env id + 与旧服务关系 | 补写后再宣称完成 |

---

## 19. 回滚与禁止覆盖规则

### 19.1 禁止覆盖（硬规则）

1. **一种 UI 形态 = 一个 Railway project（推荐）/ 至少一个独立 service。**  
   例：`high-deploy`（Gradio）与 `high-webui`（自定义 Web）必须分离。
2. **禁止** 在仍对用户/博客生效的旧 service 上，上传另一种形态的构建目录（例如把 webui 目录 `railway up` 到 Gradio 项目）。
3. **禁止** 无备份地删除旧 Domain / 旧 service，除非用户明确要求下线旧入口。
4. **禁止** 把 token、`.env`、私钥写入 Git、Docker 上下文、UPMA zip、本技能或 KK-Online 公开文件。
5. UPMA：**默认增量 merge**；禁止无确认的整站 zip 覆盖。

### 19.2 发现打错项目时

1. **立刻停止** 再次 `railway up`。
2. 记录错误的 project/service id 与错误部署时间。
3. 若错误部署已替换仍需的旧形态：在**正确**的旧部署目录重新 `railway up` 恢复；或从 Railway 部署历史回滚到上一成功版本（Dashboard）。
4. 纠正 `railway link` / 显式 `--project` / `--service` 后再发新形态到**新**项目。
5. 冒烟旧 URL + 新 URL；更新笔记说明事故与结果。

### 19.3 应用层回滚

- 保留上一成功部署目录快照或 git tag。
- 前端严重回归：redeploy 上一已知好的 commit/目录。
- 博客接错：改回上一 CTA URL，再打增量 zip merge。

### 19.4 下线流程（仅当用户明确要求）

1. 先改博客主入口到替代 URL 或「维护中」页并 UPMA merge。
2. 再删 Domain / 停 service。
3. 笔记标明下线时间与替代入口。

---

## 20. 完成定义（Definition of Done）

- [ ] 主功能 HTTPS 可打开
- [ ] Gate⑦ 冒烟通过
- [ ] 旧服务按策略保留或降为次要入口（未误覆盖）
- [ ] 博客（若有）主入口正确
- [ ] 笔记 + 记忆可交接
- [ ] 用户已知 redeploy 命令与主 URL
