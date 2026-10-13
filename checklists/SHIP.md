# 上线检查清单（SHIP）

复制到任务里勾选。对应 SKILL §13 + §18 Gate。

## 准备

- [ ] 源码定位；形态 A–F 已选（Gate①②）
- [ ] 部署目录与源码分离
- [ ] PORT + `0.0.0.0`；路径相对化
- [ ] Dockerfile + 系统库 + `.dockerignore`（无密钥）（Gate③）
- [ ] `railway.toml` / `render.yaml` 健康检查合理
- [ ] 已确认 **不会覆盖** 旧生产（SKILL §19）

## 平台

- [ ] 账号已登录（Gate④）
- [ ] 新形态使用新 project
- [ ] Deployment SUCCESS（Gate⑤）
- [ ] Domain 已生成；HTTPS 可访问（Gate⑥）

## 质量

- [ ] `GET /` 与 `GET /health`（若有）通过（Gate⑦）
- [ ] 核心 API / UI 主路径通过
- [ ] 硬刷新验证 CSS/JS
- [ ] 博客主/次入口与 UPMA 已更新（Gate⑧，若适用）
- [ ] 笔记 + 记忆已写（Gate⑨）

## 交付给用户

- [ ] 主 URL
- [ ] 次要 URL（若有）
- [ ] redeploy 命令
- [ ] 博客链接（若有）
