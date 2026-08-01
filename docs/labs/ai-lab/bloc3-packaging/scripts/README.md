# AI Lab — Deployment Scripts

This folder contains the deployment artifacts for the HikenRoot Forge AI Lab:
a self-hosted RAG and orchestration stack running on Proxmox / Debian 12.

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | Stack definition: Qdrant + n8n + n8n-task-runner + Open WebUI |
| `.env.example` | Template for environment variables (copy to `.env` and fill in) |
| `ocr-batch.py` | OCR pipeline for screenshot-heavy PDFs using minicpm-v:8b |
| `rag-server.py` | Minimal Flask UI to query the Qdrant collection (RAG) |
| `backup-workflow-ingest.json` | n8n workflow: PDF -> embeddings -> Qdrant ingestion |

## Architecture
                +------------------+
                | Ollama (host)    |  qwen3:8b, minicpm-v:8b,
                | :11434           |  nomic-embed-text
                +---------+--------+
                          ^
                          |
+-----------+    +------------+-----------+    +------------+
| Open WebUI|<-->|       Qdrant           |<-->|    n8n     |
| :3000     |    | :6333 (REST) :6334 gRPC|    | :5678 :5679|
+-----------+    +------------------------+    +------+-----+
|
+-------+--------+
| n8n-task-runner|
+----------------+

## Quick deploy

```bash
# 1. Clone the repo and cd into this directory
cd hikenroot-forge/docs/labs/ai-lab/bloc3-packaging/scripts/

# 2. Configure environment variables
cp .env.example .env
nano .env
#   - set N8N_USER and N8N_PASSWORD
#   - generate a strong N8N_RUNNERS_TOKEN: openssl rand -hex 32
#   - set N8N_HOST_URL to your IP (e.g. http://192.168.1.10:5678/)

# 3. Pull the required Ollama models on the host
ollama pull nomic-embed-text
ollama pull qwen3:8b
ollama pull minicpm-v:8b

# 4. Start the stack
docker compose up -d
docker compose ps

# 5. Open the UIs
#   - n8n editor:  http://<host>:5678
#   - Open WebUI:  http://<host>:3000
#   - Qdrant API:  http://<host>:6333
```

## Importing the ingestion workflow

In the n8n editor (`http://<host>:5678`):

1. Go to **Workflows** > **Import from File**
2. Select `backup-workflow-ingest.json`
3. Configure the credentials (Qdrant API + Ollama account) in the imported nodes
4. Drop your PDFs into the `./pdfs/` folder (mounted as `/data/pdfs` inside n8n)
5. Run the workflow manually via the **RAG-Ingest-PDFs** trigger

## Running the OCR pipeline

For PDFs that are mostly screenshots (e.g. OneNote exports), run `ocr-batch.py`
to enrich them with vision-OCR before ingestion:

```bash
export PDF_DIR=./pdfs
export OUTPUT_DIR=./ocr-output
python3 ocr-batch.py
```

The script computes a `words/KB` ratio for each PDF; PDFs below the threshold
(default 0.5) are processed page-by-page through `minicpm-v:8b`.

## Running the RAG query server

```bash
pip install flask
python3 rag-server.py
# open http://localhost:8888
```

## Notes

- **Ollama runs natively on the host** (not in Docker) due to a Blackwell GPU
  passthrough incompatibility with QEMU/KVM. Containers reach it via the Docker
  bridge gateway `http://172.17.0.1:11434`.
- The stack requires `apparmor:unconfined` on Debian 12 / Proxmox for Qdrant
  and Open WebUI to bind their sockets.
- n8n and `n8n-task-runner` images are pinned to the same version (2.11.3) to
  avoid `spawn EACCES` errors in AI Agent nodes (external task runner mode).
- `qwen3:8b` is the validated query model: thinking-mode models (deepseek-r1,
  qwen3.5:27b) leave the `content` field empty and break RAG output.
