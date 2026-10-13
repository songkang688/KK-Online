# KK Online

**KK 项目从 Git 到公网的标准上线手册与模板**

面向 `songkang688` / Barbara 的实战发布包：把「选形态 → 打 Docker 包 → Railway/Render/HF/UPMA → 冒烟 → 博客接线 → 迭代排障」打成可复用 SOP，并附带 templates、scripts、checklists。

> Grok Bot 技能 id：**`kk-online`**（本仓库 `SKILL.md` 与技能正文同步）。  
> 实战来源：人脸面部去高光（`songkang688/high`）、博客 UPMA、Railway `high-deploy` / `high-webui`。

## 何时用

- 新 Git 应用要挂公网 HTTPS
- Gradio / FastAPI / 自定义 Web / 静态博客要上线或换形态
- 博客「进入官网」接线、redeploy、排障
- 需要 Dockerfile / `railway.toml` / 冒烟脚本，而不是每次从零写

## 快速开始

```bash
# 1. 克隆本仓库（或复制 templates）
git clone https://github.com/songkang688/KK-Online.git
cd KK-Online

# 2. 读流程
#    docs/FLOW.md  ·  docs/PLATFORMS.md  ·  SKILL.md

# 3. 拷模板到你的部署目录
cp templates/Dockerfile.python-cv /path/to/deploy/Dockerfile
cp templates/railway.toml templates/dockerignore /path/to/deploy/
# dockerignore 请重命名为 .dockerignore
mv /path/to/deploy/dockerignore /path/to/deploy/.dockerignore

# 4. 按形态改 COPY/CMD 与 PORT 片段（templates/*_snippet.py）

# 5. 部署（需已 railway login）
bash scripts/railway-up.sh /path/to/deploy

# 6. 冒烟
bash scripts/smoke-http.sh https://your-app-production.up.railway.app

# 7. 勾清单
#    checklists/SHIP.md
```

Agent 用户说「发布 / 上线」时：按 `SKILL.md` **§17 一键推进** Turn 0→9 执行，并用 **§18 Gate** 卡阶段。

## 目录说明

```text
KK-Online/
├── README.md
├── LICENSE                 # MIT
├── SKILL.md                # 完整 SOP（与 Grok Bot 技能 kk-online 同步）
├── docs/
│   ├── FLOW.md             # 端到端流程详解
│   ├── PLATFORMS.md        # Railway / Render / HF / UPMA
│   ├── TROUBLESHOOTING.md  # 排障树
│   └── HISTORY.md          # 历史快照（去高光等）
├── checklists/
│   └── SHIP.md             # 上线检查清单
├── templates/
│   ├── Dockerfile.python-cv
│   ├── railway.toml
│   ├── render.yaml
│   ├── Procfile
│   ├── dockerignore
│   ├── fastapi_port_snippet.py
│   ├── gradio_port_snippet.py
│   └── busy_hidden_fix.css
└── scripts/
    ├── smoke-http.sh
    ├── railway-up.sh
    └── make-upma-zip.sh
```

## 与技能的关系

| 层级 | 内容 |
|------|------|
| Grok Bot 技能 `kk-online` | 助手执行时的权威 SOP（含一键推进、Gate、回滚规则、历史快照） |
| 本仓库 | 可公开的手册 + 可拷贝模板/脚本；方便人类与 CI 复用 |

更新流程：改 `SKILL.md` / docs / templates → 同步技能 body → push 本仓。

## 硬规则摘要

1. 先定形态 A–F，再选平台（默认计算型 → Railway）。
2. **一种产品形态 = 一个 Railway project**；禁止用 webui 覆盖仍在用的 Gradio 生产。
3. 应用必须 `0.0.0.0` + 读环境变量 `PORT`。
4. 密钥永不进 Git / 镜像 / zip / 技能正文。
5. 出网受限环境不要死磕 Gradio `share=True`。

## Owner 上下文

- GitHub：`songkang688`
- 相关应用：Face dehighlight（`high`）、博客 UPMA（`astro-aguc.upma.site`）
- 线上示例：
  - Gradio：https://high-deploy-production.up.railway.app
  - WebUI：https://high-webui-production.up.railway.app

详情见 `docs/HISTORY.md`（含 project id；**不含密钥**）。

## License

MIT — 见 [LICENSE](./LICENSE)。
