#!/usr/bin/env bash
# Transcribe one audio file to a text file. Offloads to a LAN whisper.cpp
# server when WHISPER_SERVER_URL (or --server) is set; otherwise runs
# whisper-cli locally. Language is a per-run choice; the model must be
# multilingual for anything but English.
set -euo pipefail

lang=auto
out=""
server="${WHISPER_SERVER_URL:-}"
model="${WHISPER_MODEL:-$HOME/code/whisper.cpp/models/ggml-large-v3-turbo-q8_0.bin}"
cli="${WHISPER_CLI:-$HOME/code/whisper.cpp/build/bin/whisper-cli}"
input=""

while [ $# -gt 0 ]; do
  case "$1" in
    --lang)   lang="$2"; shift 2 ;;
    --out)    out="$2"; shift 2 ;;
    --server) server="$2"; shift 2 ;;
    --model)  model="$2"; shift 2 ;;
    -*)       echo "unknown flag: $1" >&2; exit 2 ;;
    *)        input="$1"; shift ;;
  esac
done

[ -n "$input" ] || { echo "usage: transcribe.sh <audio-file> [--lang zh] [--out file.txt] [--server URL] [--model path]" >&2; exit 2; }
[ -f "$input" ] || { echo "no such file: $input" >&2; exit 2; }
command -v ffmpeg >/dev/null || { echo "ffmpeg not found (needed to decode audio)" >&2; exit 3; }

# Default output next to the input: <stem>.<lang>.txt
if [ -z "$out" ]; then
  stem="${input%.*}"
  out="${stem}.${lang}.txt"
fi

# whisper.cpp reads 16 kHz mono wav; convert whatever the input is.
wav="$(mktemp --suffix=.wav)"
trap 'rm -f "$wav"' EXIT
ffmpeg -nostdin -v error -y -i "$input" -ar 16000 -ac 1 "$wav"

if [ -n "$server" ]; then
  echo "transcribing via server: $server (lang=$lang)" >&2
  # response_format=text returns the plain transcript body.
  curl -sf --max-time 3600 "${server%/}/inference" \
    -F "file=@${wav}" \
    -F "language=${lang}" \
    -F "response_format=text" \
    -o "$out" \
    || { echo "server request failed: ${server%/}/inference" >&2; exit 4; }
else
  echo "transcribing locally: $cli (lang=$lang)" >&2
  [ -x "$cli" ] || { echo "whisper-cli not found or not executable: $cli" >&2; exit 3; }
  [ -f "$model" ] || { echo "model not found: $model" >&2; exit 3; }
  # -otxt writes one segment per line (like the server path); -of takes the stem.
  "$cli" -m "$model" -l "$lang" -np -otxt -of "${out%.txt}" -f "$wav" >/dev/null
fi

# Trim leading spaces whisper puts before each segment, and drop leading blank lines.
sed -i 's/^ *//; /./,$!d' "$out"
echo "wrote: $out" >&2
echo "$out"
