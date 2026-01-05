#!/bin/bash
# CosyVoice Launcher for Vast.ai Serverless
# This script starts the model server and PyWorker
# IMPORTANT: Set WORKER_PORT to match an existing VAST_TCP_PORT_xxx

echo "=== CosyVoice Launcher ===" | tee -a /root/debug.log
date | tee -a /root/debug.log

# Debug: Show what Vast.ai gave us
echo "=== Environment from Vast.ai ===" | tee -a /root/debug.log
env | grep -E "^VAST_|^WORKER_|^REPORT_|^CONTAINER_|^USE_SSL" | tee -a /root/debug.log

# Create log directory
mkdir -p /var/log/cosyvoice

# Model server config (these are ours, not infrastructure)
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

# Give the model a moment to start writing logs
sleep 2

# Only set REPORT_ADDR if not already set by infrastructure
if [ -z "$REPORT_ADDR" ]; then
    export REPORT_ADDR="https://run.vast.ai"
    echo "Set REPORT_ADDR=$REPORT_ADDR (default)" | tee -a /root/debug.log
fi

# CONTAINER_ID - use what infrastructure provides, or fall back
if [ -z "$CONTAINER_ID" ]; then
    export CONTAINER_ID="${VAST_CONTAINERLABEL:-cosyvoice}"
    echo "Set CONTAINER_ID=$CONTAINER_ID (default)" | tee -a /root/debug.log
fi

# WORKER_PORT - MUST match an existing VAST_TCP_PORT_xxx
# The SDK looks for VAST_TCP_PORT_{WORKER_PORT} to get the external port
# Check what ports are available and use one that exists
if [ -n "$VAST_TCP_PORT_8000" ]; then
    export WORKER_PORT=8000
    echo "Using WORKER_PORT=8000 (VAST_TCP_PORT_8000=$VAST_TCP_PORT_8000)" | tee -a /root/debug.log
elif [ -n "$VAST_TCP_PORT_18000" ]; then
    export WORKER_PORT=18000
    echo "Using WORKER_PORT=18000 (VAST_TCP_PORT_18000=$VAST_TCP_PORT_18000)" | tee -a /root/debug.log
else
    # Fall back to 8000 and hope for the best
    export WORKER_PORT=8000
    echo "WARNING: No VAST_TCP_PORT_xxx found, using WORKER_PORT=8000" | tee -a /root/debug.log
fi

# Clone our pyworker config
echo "Setting up PyWorker config..." | tee -a /root/debug.log
PYWORKER_REPO=${PYWORKER_REPO:-"https://github.com/DeepMakeLuke/cosyvoice-pyworker"}
cd /home/workspace 2>/dev/null || mkdir -p /home/workspace && cd /home/workspace
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
env | grep -E "^VAST_|^WORKER_|^REPORT_|^CONTAINER_|^USE_SSL" | tee -a /root/debug.log

# Run the worker
echo "Starting PyWorker..." | tee -a /root/debug.log
python worker.py
