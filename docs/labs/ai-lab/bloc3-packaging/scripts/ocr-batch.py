#!/usr/bin/env python3
"""
HikenRoot Forge — OCR Vision Batch Pipeline
Extracts text from screenshot-heavy PDFs (e.g. OneNote exports)
using minicpm-v:8b (vision LLM) + pdftotext (native text).
Output: enriched .txt files ready for Qdrant ingestion.

Configuration via environment variables (or defaults):
    PDF_DIR          : input directory containing PDFs        (default: ./pdfs)
    OUTPUT_DIR       : output directory for enriched .txt     (default: ./ocr-output)
    OLLAMA_URL       : Ollama API endpoint                    (default: http://localhost:11434/api/chat)
    MODEL            : vision model tag                       (default: minicpm-v:8b)
    RATIO_THRESHOLD  : words/KB ratio below which OCR runs    (default: 0.5)
    IMG_RESIZE       : max image dimension in pixels          (default: 1200)

Requirements: pdftotext, pdftoppm, ImageMagick (convert), Ollama with the vision model pulled.
"""

import os, subprocess, base64, json, urllib.request, sys, glob, shutil

PDF_DIR = os.environ.get("PDF_DIR", "./pdfs")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "./ocr-output")
TMP_DIR = "/tmp/ocr-batch"
MODEL = os.environ.get("MODEL", "minicpm-v:8b")
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434/api/chat")
RATIO_THRESHOLD = float(os.environ.get("RATIO_THRESHOLD", "0.5"))
IMG_RESIZE = int(os.environ.get("IMG_RESIZE", "1200"))

def get_pdf_ratio(pdf_path):
    """Compute words/KB ratio to detect screenshot-heavy PDFs."""
    result = subprocess.run(['pdftotext', pdf_path, '-'], capture_output=True, text=True)
    words = len(result.stdout.split())
    size_kb = os.path.getsize(pdf_path) // 1024
    return words / max(size_kb, 1), result.stdout

def pdf_to_images(pdf_path, output_prefix):
    """Convert each PDF page to a JPEG image."""
    subprocess.run(['pdftoppm', '-jpeg', '-r', '200', pdf_path, output_prefix], check=True)
    images = sorted(glob.glob(f"{output_prefix}*.jpg"))
    return images

def resize_image(img_path, size=1200):
    """Resize image to optimize VRAM usage."""
    out_path = img_path.replace('.jpg', '-resized.jpg')
    subprocess.run(['convert', img_path, '-resize', f'{size}x{size}', out_path], check=True)
    return out_path

def ocr_vision(img_path):
    """Send image to minicpm-v:8b for OCR extraction."""
    with open(img_path, "rb") as f:
        b64 = base64.b64encode(f.read()).decode()

    req = urllib.request.Request(OLLAMA_URL,
        data=json.dumps({
            "model": MODEL,
            "stream": False,
            "options": {"num_predict": 3000, "num_ctx": 4096},
            "messages": [{
                "role": "user",
                "content": "OCR this image. Output ONLY the raw text you see, line by line. No analysis, no commentary. If text is unreadable write [unclear].",
                "images": [b64]
            }]
        }).encode(),
        headers={"Content-Type": "application/json"})

    try:
        resp = json.loads(urllib.request.urlopen(req, timeout=600).read())
        return resp["message"].get("content", "")
    except Exception as e:
        print(f"  [ERROR] OCR failed: {e}")
        return ""

def process_pdf(pdf_path):
    """Process a single PDF: pdftotext + per-page vision OCR."""
    basename = os.path.splitext(os.path.basename(pdf_path))[0]
    print(f"\n{'='*60}")
    print(f"Processing: {basename}")
    print(f"{'='*60}")

    ratio, native_text = get_pdf_ratio(pdf_path)
    print(f"  Ratio: {ratio:.2f} — {'NEEDS OCR' if ratio < RATIO_THRESHOLD else 'OK'}")

    if ratio >= RATIO_THRESHOLD:
        print(f"  Skipping OCR — ratio OK")
        return None

    page_dir = os.path.join(TMP_DIR, basename)
    os.makedirs(page_dir, exist_ok=True)
    prefix = os.path.join(page_dir, "page")
    images = pdf_to_images(pdf_path, prefix)
    print(f"  Pages: {len(images)}")

    ocr_texts = []
    for i, img in enumerate(images):
        page_num = i + 1
        print(f"  OCR page {page_num}/{len(images)}...", end=" ", flush=True)
        resized = resize_image(img, IMG_RESIZE)
        text = ocr_vision(resized)
        words = len(text.split())
        print(f"{words} words")
        ocr_texts.append(f"--- PAGE {page_num} ---\n{text}")

    combined = f"# {basename}\n"
    combined += f"# Source: {os.path.basename(pdf_path)}\n"
    combined += f"# OCR enriched by {MODEL}\n\n"
