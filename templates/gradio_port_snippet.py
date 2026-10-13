"""KK Online — Gradio launch snippet (形态 A). share=False for PaaS."""
import os

# after: app = build_app()  or  gr.Blocks(...)
port = int(os.environ.get("PORT", "7860"))
app.launch(
    server_name="0.0.0.0",
    server_port=port,
    # share=False  # never rely on Gradio FRP inside production containers
)
