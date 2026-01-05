#!/bin/bash
# CosyVoice Launcher for Vast.ai Serverless
# This script starts the model server and PyWorker

echo "=== CosyVoice Launcher ===" | tee -a /root/debug.log
date | tee -a /root/debug.log

# Debug: Show what Vast.ai gave us
echo "=== Environment from Vast.ai ===" | tee -a /root/debug.log
env | grep -E "^VAST_|^WORKER_|^REPORT_|^CONTAINER_" | tee -a /root/debug.log

# Create log directory
mkdir -p /var/log/cosyvoice

# Model server config
export MODEL_SERVER_PORT=${MODEL_SERVER_PORT:-18000}
export MODEL_LOG_FILE=${MODEL_LOG_FILE:-/var/log/cosyvoice/server.log}

echo "MODEL_SERVER_PORT=$MODEL_SERVER_PORT" | tee -a /root/debug.log
echo "MODEL_LOG_FILE=$MODEL_LOG_FILE" | tee -a /root/debug.log

# Start the model server in the background
echo "Starting CosyVoice model server..." | tee -a /root/debug.log
cd /app
python /app/worker_serverless.py > "$MODEL_LOG_FILE" 2>&1 &
MODEL_PID=$!
echo "Model server PID: $MODEL_PID" | tee -a /root/debug.log

# Wait for model server to start writing logs
sleep 3

# Clone our pyworker config
echo "Setting up PyWorker config..." | tee -a /root/debug.log
PYWORKER_REPO=${PYWORKER_REPO:-"https://github.com/DeepMakeLuke/cosyvoice-pyworker"}
mkdir -p /home/workspace
cd /home/workspace
rm -rf pyworker-config
git clone "$PYWORKER_REPO" pyworker-config
cd pyworker-config

# Install requirements
if [ -f requirements.txt ]; then
    echo "Installing requirements..." | tee -a /root/debug.log
    pip install -r requirements.txt
fi

# Final env check
echo "=== Final Environment ===" | tee -a /root/debug.log
env | grep -E "^VAST_|^WORKER_|^REPORT_|^CONTAINER_" | tee -a /root/debug.log

# Run worker.py (env vars are set inside worker.py before SDK import)
echo "Starting PyWorker..." | tee -a /root/debug.log
python worker.py
