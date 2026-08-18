#!/usr/bin/env bash
out="$1"
while true; do
  read u a < <(free -m | awk '/Mem:/{print $3, $7}')
  printf '%s used_MiB=%s avail_MiB=%s\n' "$(date +%H:%M:%S)" "$u" "$a" >> "$out"
  sleep 8
done
