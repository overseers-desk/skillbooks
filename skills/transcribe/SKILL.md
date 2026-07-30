---
name: transcribe
description: Trigger when the user asks to transcribe an audio or voice recording (.m4a, .wav, .mp3, voice memo) into a text file, or dictate a recording to text — in any language. Offloads to a LAN whisper.cpp server when one is configured, else runs locally on the GPU.
argument-hint: <audio-file> [--lang zh|en|auto] [--out file.txt] [--server URL]
allowed-tools: Bash, Read
---

## What this skill does

Turns one audio file into one text file. It decodes any format ffmpeg reads (m4a, mp3, wav, ogg…) to the 16 kHz mono wav whisper.cpp expects, transcribes it, and writes the transcript to a `.txt` file next to the input.

Two paths, chosen by whether a server is configured:

- **Server** — when `WHISPER_SERVER_URL` (or `--server`) is set, the audio is POSTed to a LAN whisper.cpp server's `/inference` endpoint. Use this from a laptop or a memory-limited device that should not transcribe locally.
- **Local** — otherwise `whisper-cli` runs on this machine. On a CUDA host this is the fast path and needs no server.

Language is per run (`--lang`, default `auto`). Anything but English needs a multilingual model; the local default model is multilingual, and a server only returns non-English if the model it loaded is multilingual too.

## How to invoke

Run the driver directly — do not spawn a subagent.

```bash
${CLAUDE_PLUGIN_ROOT}/skills/transcribe/transcribe.sh <audio-file> [flags]
```

Flags:

- `--lang <code>` — spoken language: `zh`, `en`, `auto` (default `auto`). Sets the output filename suffix.
- `--out <file.txt>` — output path. Default: `<input-stem>.<lang>.txt` beside the input.
- `--server <URL>` — whisper server base URL, e.g. `http://192.168.9.150:8090`. Overrides `WHISPER_SERVER_URL`.
- `--model <path>` — model for the local path. Overrides `WHISPER_MODEL`.

The driver prints the output path on stdout. After it returns, `Read` that file to hand the transcript to the user.

## Configuration (environment)

- `WHISPER_SERVER_URL` — set it and the skill offloads to that server. Unset and it runs locally.
- `WHISPER_MODEL` — local model path. Defaults to a multilingual whisper.cpp model under `$HOME/code/whisper.cpp/models`.
- `WHISPER_CLI` — path to `whisper-cli`. Defaults under `$HOME/code/whisper.cpp/build`.

## Prerequisites

- `ffmpeg` — decodes the input to wav. `sudo apt install ffmpeg` (or your distro's equivalent).
- For the local path: a built `whisper-cli` and a model file. For the server path: `curl` and a reachable whisper.cpp server.
