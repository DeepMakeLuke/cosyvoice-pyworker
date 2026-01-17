#!/usr/bin/env python3
"""
CosyVoice PyWorker configuration for Vast.ai Serverless.

This file is loaded by vast-pyworker via PYWORKER_REPO.
It configures the PyWorker proxy to communicate with our CosyVoice FastAPI server.
"""

import os

# Model server configuration
# CosyVoice FastAPI server runs on port 50000
MODEL_SERVER_URL = "http://127.0.0.1"
MODEL_SERVER_PORT = int(os.environ.get("MODEL_SERVER_PORT", "50000"))
MODEL_LOG_FILE = os.environ.get("MODEL_LOG_FILE", "/var/log/portal/cosyvoice.log")

from vastai import (
    Worker,
    WorkerConfig,
    HandlerConfig,
    LogActionConfig,
    BenchmarkConfig,
)


def benchmark_generator():
    """Generate a benchmark request for performance testing."""
    return {
        "tts_text": "Hello, this is a test of the text to speech system.",
        "spk_id": "中文女"
    }


def workload_calculator(payload: dict) -> float:
    """
    Calculate workload based on text length.
    Longer text = more compute time.
    """
    text = payload.get("tts_text", "")
    return max(1.0, float(len(text)))


# Build the worker configuration
worker_config = WorkerConfig(
    model_server_url=MODEL_SERVER_URL,
    model_server_port=MODEL_SERVER_PORT,
    model_log_file=MODEL_LOG_FILE,

    handlers=[
        # SFT inference endpoint (preset voices)
        HandlerConfig(
            route="/inference_sft",
            allow_parallel_requests=False,  # TTS is sequential on GPU
            max_queue_time=120.0,  # 2 minutes max wait
            workload_calculator=workload_calculator,
            benchmark_config=BenchmarkConfig(
                generator=benchmark_generator,
                runs=2,
                concurrency=1,
            ),
        ),
    ],

    # Log-based readiness detection
    log_action_config=LogActionConfig(
        # Pattern that indicates model is ready
        # CosyVoice FastAPI server logs this when uvicorn starts
        on_load=["Uvicorn running on"],

        # Patterns that indicate errors
        on_error=[
            "RuntimeError:",
            "Traceback (most recent call last):",
            "CUDA out of memory",
            "Exception:",
            "ERROR",
        ],

        # Informational patterns
        on_info=[
            "Loading model",
            "INFO:",
        ],
    ),
)

# Start the worker
if __name__ == "__main__":
    Worker(worker_config).run()
