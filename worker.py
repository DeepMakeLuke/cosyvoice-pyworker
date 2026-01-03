#!/usr/bin/env python3
"""
CosyVoice PyWorker configuration for Vast.ai Serverless.

This file is loaded by vast-pyworker via PYWORKER_REPO.
It configures the PyWorker proxy to communicate with our CosyVoice model server.
"""

import os
from vastai import (
    Worker,
    WorkerConfig,
    HandlerConfig,
    LogActionConfig,
    BenchmarkConfig,
)

# Model server configuration
# The model server runs on port 18000 inside the container
MODEL_SERVER_URL = "http://127.0.0.1"
MODEL_SERVER_PORT = int(os.environ.get("MODEL_SERVER_PORT", "18000"))
MODEL_LOG_FILE = os.environ.get("MODEL_LOG_FILE", "/var/log/cosyvoice/server.log")


def benchmark_generator():
    """Generate a benchmark request for performance testing."""
    return {
        "text": "Hello, this is a test of the text to speech system.",
        "speaker": "english_female"
    }


def workload_calculator(payload: dict) -> float:
    """
    Calculate workload based on text length.
    Longer text = more compute time.
    """
    text = payload.get("text", "")
    # Rough estimate: 1 workload unit per 100 characters
    return max(1.0, len(text) / 100.0)


# Build the worker configuration
worker_config = WorkerConfig(
    model_server_url=MODEL_SERVER_URL,
    model_server_port=MODEL_SERVER_PORT,
    model_log_file=MODEL_LOG_FILE,

    handlers=[
        # Main TTS generation endpoint - has benchmark config
        HandlerConfig(
            route="/generate",
            allow_parallel_requests=False,  # TTS is sequential on GPU
            max_queue_time=120.0,  # 2 minutes max wait
            workload_calculator=workload_calculator,
            benchmark_config=BenchmarkConfig(
                generator=benchmark_generator,
                runs=2,  # Run 2 benchmark requests
                concurrency=1,  # One at a time
            ),
        ),
        # Health check endpoint
        HandlerConfig(
            route="/health",
            allow_parallel_requests=True,
        ),
        # Readiness check endpoint
        HandlerConfig(
            route="/ready",
            allow_parallel_requests=True,
        ),
        # Speaker list endpoint
        HandlerConfig(
            route="/speakers",
            allow_parallel_requests=True,
        ),
    ],

    # Log-based readiness detection
    # PyWorker watches the model log file for these patterns
    log_action_config=LogActionConfig(
        # Pattern that indicates model is ready (PREFIX-BASED matching!)
        # This line must appear at the START of a log line
        on_load=["CosyVoice model loaded successfully"],

        # Patterns that indicate errors
        on_error=[
            "RuntimeError:",
            "Traceback (most recent call last):",
            "CUDA out of memory",
            "Exception:",
        ],

        # Informational patterns (for logging only)
        on_info=[
            "Loading model",
            "Downloading",
            "Starting",
        ],
    ),
)

# Start the worker
if __name__ == "__main__":
    Worker(worker_config).run()
