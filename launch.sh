#!/bin/bash
# CosyVoice Launcher for Vast.ai Serverless
# This script starts the CosyVoice FastAPI model server
# PyWorker is handled separately via PYWORKER_REPO

set -e

echo "=== CosyVoice Model Server Launcher ==="
date

# Create log directory
mkdir -p /var/log/portal

# Set PYTHONPATH for CosyVoice third-party modules
export PYTHONPATH=/opt/CosyVoice/third_party/AcademiCodec:/opt/CosyVoice/third_party/Matcha-TTS:$PYTHONPATH

cd /opt/CosyVoice

# Start CosyVoice FastAPI server (this blocks)
echo "Starting CosyVoice FastAPI server on port 50000..."
exec python runtime/python/fastapi/server.py \
    --port 50000 \
    --model_dir pretrained_models/Fun-CosyVoice3-0.5B \
    2>&1 | tee /var/log/portal/cosyvoice.log
