#!/bin/bash
# CosyVoice Launcher for Vast.ai Serverless
# Strategy: Start model server, then use Vast.ai's official start_server.sh
# Don't manually handle env vars - let their tested script do it

echo "=== CosyVoice Launcher ===" | tee -a /root/debug.log
date | tee -a /root/debug.log

# Create log directory
mkdir -p /var/log/cosyvoice

# Model server config
export MODEL_SERVER_PORT=${MODEL_SERVER_PORT:-18000}
export MODEL_LOG_FILE=${MODEL_LOG_FILE:-/var/log/cosyvoice/server.log}

echo "Starting CosyVoice model server on port $MODEL_SERVER_PORT..." | tee -a /root/debug.log
cd /app
python /app/worker_serverless.py > "$MODEL_LOG_FILE" 2>&1 &
MODEL_PID=$!
echo "Model server PID: $MODEL_PID" | tee -a /root/debug.log

# Wait for model server to start
sleep 3

# Set PYWORKER_REPO to our config (this is the only thing we need to set)
export PYWORKER_REPO="https://github.com/DeepMakeLuke/cosyvoice-pyworker"

# Use Vast.ai's official start_server.sh - it handles all env vars correctly
echo "Running Vast.ai start_server.sh..." | tee -a /root/debug.log
wget -qO- https://raw.githubusercontent.com/vast-ai/vast-pyworker/main/start_server.sh | bash
