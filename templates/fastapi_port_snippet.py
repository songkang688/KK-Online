"""KK Online — paste into FastAPI web_server (形态 B/C). No secrets."""
import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

HOST = "0.0.0.0"
PORT = int(os.environ.get("PORT", "7860"))

app = FastAPI(title="my-app", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten to blog origin in production if needed
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"ok": True}


if __name__ == "__main__":
    print(f"starting on http://{HOST}:{PORT}", flush=True)
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
