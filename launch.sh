#!/bin/bash
# CosyVoice Launcher for Vast.ai Serverless
# This script starts the model server and PyWorker

echo "=== CosyVoice Launcher ===" | tee -a /root/debug.log
date | tee -a /root/debug.log

# Create log directory
mkdir -p /var/log/cosyvoice

# Set defaults
export MODEL_SERVER_PORT=${MODEL_SERVER_PORT:-18000}
export MODEL_LOG_FILE=${MODEL_LOG_FILE:-/var/log/cosyvoice/server.log}

echo "MODEL_SERVER_PORT=$MODEL_SERVER_PORT" | tee -a /root/debug.log
echo "MODEL_LOG_FILE=$MODEL_LOG_FILE" | tee -a /root/debug.log

# Start the model server in the background
# The model server should be at /app/worker_serverless.py in the Docker image
echo "Starting CosyVoice model server..." | tee -a /root/debug.log
cd /app
python /app/worker_serverless.py > "$MODEL_LOG_FILE" 2>&1 &
MODEL_PID=$!
echo "Model server started with PID: $MODEL_PID" | tee -a /root/debug.log

# Give the model a moment to start writing logs
sleep 2

# Now run the Vast.ai PyWorker bootstrap
# This sets up env vars (REPORT_ADDR, etc.) and runs our worker.py
echo "Starting PyWorker bootstrap..." | tee -a /root/debug.log

# Download and run their start_server.sh if not already set up
if [ ! -d "/home/workspace/vast-pyworker" ]; then
    echo "Downloading vast-pyworker..." | tee -a /root/debug.log
    mkdir -p /home/workspace
    cd /home/workspace
    git clone https://github.com/vast-ai/vast-pyworker
fi

# Set required env vars (same as their start_server.sh)
export REPORT_ADDR=${REPORT_ADDR:-"https://run.vast.ai"}
export CONTAINER_ID=${CONTAINER_ID:-${VAST_CONTAINERLABEL:-"cosyvoice"}}
export WORKER_PORT=${WORKER_PORT:-3000}
export USE_SSL=${USE_SSL:-"true"}

echo "REPORT_ADDR=$REPORT_ADDR" | tee -a /root/debug.log
echo "CONTAINER_ID=$CONTAINER_ID" | tee -a /root/debug.log

# Clone our pyworker config if PYWORKER_REPO is set
if [ -n "$PYWORKER_REPO" ]; then
    echo "Cloning PYWORKER_REPO: $PYWORKER_REPO" | tee -a /root/debug.log
    cd /home/workspace
    rm -rf pyworker-config
    git clone "$PYWORKER_REPO" pyworker-config
    cd pyworker-config

    # Install requirements if present
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt
    fi

    # Run the worker
    echo "Starting PyWorker..." | tee -a /root/debug.log
    python worker.py
else
    echo "ERROR: PYWORKER_REPO not set!" | tee -a /root/debug.log
    exit 1
fi
