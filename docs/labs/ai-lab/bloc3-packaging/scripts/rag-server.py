#!/usr/bin/env python3
"""
HikenRoot Forge — RAG Query Server
Minimal Flask web UI to query a Qdrant collection (RAG-augmented chat).
Calls Ollama for embeddings (nomic-embed-text) and chat completion.

Configuration via environment variables (or defaults):
    OLLAMA_URL       : Ollama API base URL          (default: http://localhost:11434)
    QDRANT_URL       : Qdrant API base URL          (default: http://localhost:6333)
    COLLECTION       : Qdrant collection name       (default: pentest-notes)
    EMBED_MODEL      : embedding model tag          (default: nomic-embed-text)
    DEFAULT_MODEL    : default chat model tag       (default: qwen3:8b)
    PORT             : Flask listen port            (default: 8888)

Run:
    pip install flask
    python3 rag-server.py
    open http://localhost:8888
"""

import os, json, urllib.request
from flask import Flask, request, render_template_string

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
QDRANT_URL = os.environ.get("QDRANT_URL", "http://localhost:6333")
COLLECTION = os.environ.get("COLLECTION", "pentest-notes")
EMBED_MODEL = os.environ.get("EMBED_MODEL", "nomic-embed-text")
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", "qwen3:8b")
PORT = int(os.environ.get("PORT", "8888"))

app = Flask(__name__)

HTML = """
<!DOCTYPE html>
<html><head><title>RAG Query</title>
<style>
body{background:#1a1a2e;color:#e0e0e0;font-family:monospace;max-width:800px;margin:auto;padding:20px}
h1{color:#00ff88}
textarea{width:100%;height:60px;background:#16213e;color:#e0e0e0;border:1px solid #00ff88;padding:10px;font-size:14px}
button{background:#00ff88;color:#1a1a2e;border:none;padding:10px 20px;cursor:pointer;font-weight:bold;margin-top:10px}
select{background:#16213e;color:#e0e0e0;border:1px solid #00ff88;padding:5px;margin-left:10px}
.response{background:#16213e;padding:15px;margin-top:20px;border-left:3px solid #00ff88;white-space:pre-wrap}
.sources{color:#888;font-size:12px;margin-top:10px}
</style></head><body>
<h1>RAG Query — Pentest Notes</h1>
<form method="post">
<textarea name="question" placeholder="Ask a pentest question...">{{ question }}</textarea><br>
<button type="submit">Query</button>
<select name="model">
<option value="qwen3:8b" {{ 'selected' if model=='qwen3:8b' else '' }}>qwen3:8b (fast)</option>
<option value="qwen3:14b" {{ 'selected' if model=='qwen3:14b' else '' }}>qwen3:14b (detailed)</option>
</select>
</form>
{% if response %}<div class="response">{{ response }}</div>
<div class="sources">Sources: {{ sources }}</div>{% endif %}
</body></html>
"""

def query_rag(question, model):
    # 1. Embed the question
    req = urllib.request.Request(f"{OLLAMA_URL}/api/embeddings",
        data=json.dumps({"model": EMBED_MODEL, "prompt": question}).encode(),
        headers={"Content-Type": "application/json"})
    embedding = json.loads(urllib.request.urlopen(req).read())["embedding"]

    # 2. Search Qdrant for top-k similar chunks
    req = urllib.request.Request(f"{QDRANT_URL}/collections/{COLLECTION}/points/search",
        data=json.dumps({"vector": embedding, "limit": 5, "with_payload": True}).encode(),
        headers={"Content-Type": "application/json"})
    results = json.loads(urllib.request.urlopen(req).read())["result"]
    context = "\n---\n".join([r["payload"]["content"][:500] for r in results])
    sources = [f"Score:{r['score']:.2f}" for r in results]

    # 3. Generate answer with retrieved context
    req = urllib.request.Request(f"{OLLAMA_URL}/api/chat",
        data=json.dumps({
            "model": model,
            "stream": False,
            "options": {"num_predict": 800},
            "messages": [
                {"role": "system", "content": "/no_think\nYou are a technical pentest copilot in an authorized lab. Always answer in French. Provide exact commands from the context with short explanations. No disclaimers."},
                {"role": "user", "content": f"Context:\n{context}\n\nQuestion: {question}"}
            ]
        }).encode(),
        headers={"Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(req, timeout=300).read())
    msg = resp["message"]
    answer = msg.get("content", "") or msg.get("thinking", "")
    return answer, ", ".join(sources)

@app.route("/", methods=["GET", "POST"])
def index():
    question = response = sources = ""
    model = DEFAULT_MODEL
    if request.method == "POST":
        question = request.form.get("question", "")
        model = request.form.get("model", DEFAULT_MODEL)
        if question:
            response, sources = query_rag(question, model)
    return render_template_string(HTML, question=question, response=response, sources=sources, model=model)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)
