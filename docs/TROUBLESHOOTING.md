# 排障树

权威版见 [SKILL.md](../SKILL.md) §11。

```text
页面打不开
  → Domain 是否生成？Deployment 是否 SUCCESS？健康检查是否杀进程？

处理按钮无响应 / 5xx
  → railway logs；模型路径；内存；请求体大小

「一直处理中」但已有耗时 / 结果 meta
  → 后端多半已成功：CSS .busy{display:grid} 盖过 [hidden]
  → 修复：templates/busy_hidden_fix.css
  → JS finally 强制 hidden；等图片 onload；用户硬刷新

CORS
  → allow_origins；或同源 StaticFiles mount

HF / Gradio share 失败
  → 停；改 Railway
  → 特征：dial tcp 198.18.0.1:7000: i/o timeout

Build 缺 libGL
  → Dockerfile 补 OpenCV 系统库（templates/Dockerfile.python-cv）

打到错误 Railway 项目
  → 立刻停；按 SKILL §19 回滚/纠正 link
```

## 本地端口冲突

- Gradio 常用 7860；薄 API 常用 7861 → 本地冒烟用 **7862**
