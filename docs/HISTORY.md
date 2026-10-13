# 历史快照（KK 实战记忆）

> 截至 **2026-10-13**（Asia/Singapore）。**不含密钥。** 新项目勿把旧 URL 当死命令。  
> 与技能 SKILL.md §14 同步维护。

## 人物与账号

- 用户：Barbara；中文简体
- GitHub：`songkang688`
- Hugging Face：`kangkang6497`（Gradio Space 免费档可能不可用）
- Railway CLI 曾用邮箱：`1621859371@qq.com`

## 核心应用：人脸面部去高光

- GitHub：`songkang688/high`
- 技术：MediaPipe FaceLandmarker + OpenCV；模式「常用 / 高保真 / 最高质量」等
- 薄 API 本地端口习惯 **7861**；Gradio **7860**

### 服务 A — Gradio

- 目录习惯：`high-deploy`
- Project ID：`a67ee9b9-c530-44a6-b9b0-c1fedc35478c`
- URL：https://high-deploy-production.up.railway.app
- **勿被 webui 覆盖**

### 服务 B — 自定义全屏 Web

- 目录习惯：`high-webui`
- Project ID：`a3cd50c2-0ec5-490b-bbc2-f2b5312fa7a9`
- Service ID：`6e3612d6-2d82-4e88-9ca2-1438f18d214f`
- Environment production：`394d8875-cd76-415f-910d-d32204ffc389`
- URL：https://high-webui-production.up.railway.app
- Dashboard：https://railway.com/project/a3cd50c2-0ec5-490b-bbc2-f2b5312fa7a9/service/6e3612d6-2d82-4e88-9ca2-1438f18d214f
- 用户选择：rebuild-pyqt-as-web；全屏新标签

### 博客 / UPMA

- 博客：https://astro-aguc.upma.site
- 项目页：`projects/face-dehighlight.html`
- 嵌入壳：`demos/face-dehighlight-official.html`
- UPMA project id：`310dacff-fa40-4db7-b452-86656a742fb4`

## 已踩坑

1. Gradio share / Cloudflare tunnel 在受限出口失败 → Railway
2. HF 免费无法建 Gradio Space → 勿卡死
3. 「处理中」假死：`.busy` 盖过 `[hidden]` → `busy_hidden_fix.css`
4. 多形态必须分 project
