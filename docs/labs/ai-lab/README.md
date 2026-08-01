# AI Lab — On-Premises RAG & Orchestration Platform

> **Portfolio project** — End-to-end on-premises AI stack for pentest knowledge management and offensive security workflow automation. Demonstrates LLM infrastructure design, retrieval-augmented generation (RAG), and orchestration on a self-hosted environment.

---

## Objective

This lab simulates a complete mission of an **AI Infrastructure Architect** building a privacy-first, fully on-premises AI platform. No cloud APIs, no data leaving the perimeter — a constraint that mirrors real-world requirements for law firms, defense contractors, healthcare providers, and other regulated industries (GDPR, secret professionnel).

The platform is operational and indexes **1485 chunks** across 32 documents (20 PDFs + 12 OCR-enriched text files) in a Qdrant vector database, queried by a locally-hosted LLM in around 6 seconds per query.

| Domain | Tools | Status |
|---|---|---|
| LLM serving on host (no VM, no Docker) | Ollama, NVIDIA driver 570, CUDA 12.8 | OK |
| Vision OCR pipeline (screenshot-heavy PDFs) | minicpm-v:8b, pdftoppm, ImageMagick | OK |
| Vector database | Qdrant 1.x (sparse + dense ready) | OK |
| RAG ingestion workflow | n8n 2.11.3, LangChain nodes | OK |
| RAG query server | Flask, qwen3:8b (validated against thinking-mode trap) | OK |
| Web UI for chat | Open WebUI with native Qdrant integration | OK |
| Cross-node API access | Beelink + Battlebox -> MS-02 Ollama API | OK |
| Documentation & lessons learned | Markdown, version-pinned compose | OK |

---

## Simulated role

**AI Infrastructure Architect** — tasked by a client (e.g. a law firm) to:

1. **Design** a fully on-premises LLM platform compatible with strict confidentiality requirements
2. **Validate** GPU passthrough and driver compatibility on a Blackwell-generation card
3. **Deploy** the RAG stack (vector DB, ingestion, query, web UI) with version pinning and reproducible compose
4. **Build** an OCR pipeline for screenshot-heavy source material (e.g. exported notes, scanned documents)
5. **Index** the document corpus and validate end-to-end retrieval quality
6. **Document** all technical pitfalls discovered along the way (vendor bugs, model selection traps, OS-level constraints)

---

## Architecture
            +-----------------------------------------------+
            |  MS-02 — Primary AI Node                      |
            |  Core Ultra 9 285HX | 192 GB DDR5 ECC         |
            |  RTX PRO 4000 Blackwell 24 GB GDDR7 ECC       |
            |                                               |
            |  +-----------------------------------------+  |
            |  | Ollama (NATIVE on host — not in Docker) |  |
            |  |   qwen3:8b        (RAG query, validated)|  |
            |  |   qwen3.5:27b     (premium reports)     |  |
            |  |   minicpm-v:8b    (vision OCR)          |  |
            |  |   nomic-embed-text (embeddings)         |  |
            |  +-----------------------+-----------------+  |
            |                          ^                    |
            |                          | http (bridge gw)   |
            |                          |                    |
            |  +-----------------------+-----------------+  |
            |  | Docker Compose stack                    |  |
            |  |   Qdrant     :6333 / :6334              |  |
            |  |   n8n        :5678 / :5679              |  |
            |  |   n8n-task-runner (external mode)       |  |
            |  |   Open WebUI :3000                      |  |
            |  +-----------------------------------------+  |
            +-----------------------------------------------+
                        ^                          ^
                        |                          |
            +-----------+-----------+   +----------+-----------+
            | Beelink (Ollama WSL)  |   | Battlebox (Ollama WSL)|
            | cross-node API calls  |   | qwen3-coder copilot   |
            +-----------------------+   +-----------------------+

---

## Structure

| Folder | Content |
|---|---|
| `bloc1-infra-llm/` | LLM infrastructure: native Ollama install on Blackwell, model selection, cross-node API access |
| `bloc2-rag-pipeline/` | RAG pipeline: Qdrant stack deployment, PDF ingestion, OCR pipeline, end-to-end validation |
| `bloc3-packaging/` | Deployment artifacts: `docker-compose.yml`, scripts (`ocr-batch.py`, `rag-server.py`), n8n workflow export, deployment runbooks |

---

## Key lessons learned

These are the real engineering hurdles encountered during the build. They are documented in detail in the corresponding write-ups.

- **Blackwell GPU + QEMU/KVM**: PCI passthrough is broken on the RTX PRO 4000 (NVIDIA-confirmed bug). Ollama cannot run in a VM or in Docker with GPU passthrough on this generation. **Solution**: run Ollama natively on the host, expose the API on the Docker bridge gateway (`http://172.17.0.1:11434`) for containers to consume.

- **Thinking-mode trap in RAG**: Models like `deepseek-r1:8b`, `qwen3:14b`, and `qwen3.5:27b` emit their final answer in the `thinking` field with an empty `content` field. RAG pipelines that read `content` get blank responses. **Solution**: use `qwen3:8b` for query — content field properly populated, French output, around 6 seconds latency.

- **n8n external task runner**: AI Agent nodes throw `spawn EACCES` errors when n8n and its task-runner image versions diverge. **Solution**: pin both `n8nio/n8n` and `n8nio/runners` to the exact same version (2.11.3 here), run the runner in external mode with `N8N_RUNNERS_MODE=external` and broker URI `http://n8n:5679`.

- **AppArmor on Debian 12 / Proxmox**: Qdrant and Open WebUI fail to bind their internal sockets with `PermissionDenied`. **Solution**: add `security_opt: ["apparmor:unconfined"]` to both containers.

- **Qdrant payload field naming**: the LangChain Qdrant node stores content under the `content` key, not `text`. Queries reading `text` return empty results. Minor but documented.

- **OCR on screenshot-heavy PDFs**: `pdftotext` extracts almost nothing from OneNote-style exports where 50%+ of pages are screenshots. Tested `tesseract` (fails on dark terminal backgrounds), `gemma4:e4b` (outputs `[unclear]`), `qwen3.5:27b` (thinking-mode trap again). **Validated solution**: `minicpm-v:8b` via Ollama API, 4.4 GB VRAM, no thinking mode, accurate extraction of hashes, credentials, IPs from terminal screenshots. 5-8x content gain vs `pdftotext` alone.

---

## Reproducing this lab

The full deployment is documented in `bloc3-packaging/scripts/README.md`. Short version:

```bash
cd docs/labs/ai-lab/bloc3-packaging/scripts/
cp .env.example .env       # fill in your own secrets
docker compose up -d
```

Then pull the required Ollama models on the host (`nomic-embed-text`, `qwen3:8b`, `minicpm-v:8b`), import the n8n workflow, and ingest your PDFs.

---

## Status

- Phase 2 — RAG validated end-to-end (1485 points indexed in `pentest-notes` collection)
- Next: hybrid search (BM25 + dense vectors), Q&A evaluation pipeline, structured chunking by document section
