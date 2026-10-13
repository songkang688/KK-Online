# 平台说明：Railway / Render / HF / UPMA

细节与命令以 [SKILL.md](../SKILL.md) §4 为准。

## Railway（默认）

- **适合：** Dockerfile Web（Gradio、FastAPI、SPA+API）
- **模型：** Workspace → Project → Environment → Service → Deployment
- **公网：** Settings → Networking → **Generate Domain** → `*.up.railway.app`
- **CLI：** `railway whoami` / `railway up -y --detach` / `railway logs`
- **配置：** `templates/railway.toml`
- **多形态：** 一种 UI 形态一个 project；禁止覆盖仍在用的旧生产

## Render（备选）

- Docker Web Service / Blueprint（`templates/render.yaml`）
- 注入 `PORT`；URL `*.onrender.com`
- **免费档约 15 分钟休眠**；冷启动慢 → 不适合苛刻的「官网主入口」除非用户接受

## Hugging Face Spaces

- 免费账号常无法建 Gradio Space；先确认配额与 write token
- `sdk: gradio` + `app_file`；或 Docker SDK
- 无 token 时不要假装能从沙箱创建；失败立即回退 Railway

## UPMA（静态）

- 博客 / 介绍页 / 游戏 `dist` / iframe 壳
- **增量 zip + merge**（`scripts/make-upma-zip.sh`）
- 禁止无确认整站覆盖；zip 内勿含密钥

## 临时通道（非生产）

- Gradio `share=True`、Cloudflare tunnel：出网受限环境常失败（DNS sinkhole / UDP 拦）
- 链接会过期 → 只用 PaaS 做官网
