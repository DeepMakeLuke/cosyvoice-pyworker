# CosyVoice PyWorker

PyWorker configuration for CosyVoice TTS on Vast.ai Serverless.

## Usage

This repository is used with Vast.ai Serverless templates via `PYWORKER_REPO`:

```bash
export PYWORKER_REPO=https://github.com/DeepMakeLuke/cosyvoice-pyworker
```

## Files

- `worker.py` - PyWorker configuration (handlers, benchmarks, log detection)
- `requirements.txt` - Additional Python dependencies (vastai-sdk installed by bootstrap)

## Configuration

Environment variables:
- `MODEL_SERVER_PORT` - Port for CosyVoice model server (default: 18000)
- `MODEL_LOG_FILE` - Path to model server log file (default: /var/log/cosyvoice/server.log)

## Related

- Docker image: `dragontamer80085/cosyvoice-serverless`
- Main project: BookSpeak (private)
