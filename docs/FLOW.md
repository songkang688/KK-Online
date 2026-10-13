# 端到端流程详解

权威细则见根目录 [SKILL.md](../SKILL.md)。本文是人类可读的流程展开。

## 总览

```text
源码 → ①摸清 → ②定形态A–F → ③部署包 → ④登录 → ⑤部署 → ⑥域名
     → ⑦冒烟 → ⑧博客接线 → ⑨笔记 → ⑩迭代
静态线：③' 改文件/zip → UPMA merge → ⑦' 预览
```

用户说「发布/上线」时，助手按 **SKILL §17 一键推进** Turn 0–9 执行，并用 **§18 Gate** 卡关。

## 阶段说明

### ① 摸清产物

读 README、入口、`requirements.txt`、模型路径、是否 GPU、是否已有公网 URL。产出笔记草稿。

**Gate①：** 入口/依赖/模型策略清楚。

### ② 定形态

| 代号 | 含义 | 默认平台 |
|------|------|----------|
| A | 已有 Gradio/Streamlit | Railway |
| B | 桌面 GUI → 重建 Web | **新** Railway project |
| C | 已有 Web+API | Railway |
| D | 静态站/游戏 dist | UPMA |
| E | 临时 share/隧道 | 勿作生产 |
| F | HF Spaces | 账号允许才用 |

**Gate②：** 形态+平台+「是否新建 project」已定。

### ③ 打部署包

从 `templates/` 拷贝 Dockerfile、`railway.toml`、`.dockerignore`；改 PORT/`0.0.0.0`；无密钥。

**Gate③：** 包可构建或配置齐全。

### ④–⑥ 账号 · 部署 · 域名

`railway login` → `whoami` →（新）`init` 或 link **正确** ids → `scripts/railway-up.sh` → SUCCESS → Generate Domain。

**Gate④/⑤/⑥：** 登录成功 / SUCCESS / HTTPS 可访问。

### ⑦ 冒烟

`scripts/smoke-http.sh <URL>` + UI 主路径。见 SKILL §9。

### ⑧ 博客接线

主 CTA `target="_blank"` 全屏，或 iframe 嵌入页；UPMA 增量 zip（`scripts/make-upma-zip.sh`）。

### ⑨ 笔记

URL、project/service/env id、与旧服务关系、冒烟日期（Asia/Singapore）。

### ⑩ 迭代

同目录 redeploy；**先确认 project id**（SKILL §19）。

## 工具脚本

| 脚本 | 作用 |
|------|------|
| `scripts/railway-up.sh` | 部署 |
| `scripts/smoke-http.sh` | HTTP 冒烟 |
| `scripts/make-upma-zip.sh` | UPMA 增量包 |
