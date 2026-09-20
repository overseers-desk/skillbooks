# The bridge, preserved

Everything that makes this work lives outside version control, in a wrapper script and a preload under a home directory. This file records it so a rebuilt machine does not have to rediscover a night's worth of findings.

## What the wrapper is for

A Tcl dispatcher runs each worker by shelling out to a binary called `claude`, resolved through PATH. A script of that name, placed earlier in PATH for one command, intercepts the call and points it at a local model. It changes nothing else about how the dispatcher works.

The directory holding it stays off the general PATH. Other work on the host shells out to `claude` and must keep reaching the real one.

## The operative lines

```sh
DIRECT_MODEL="qwen3-30b-128k"
SPAR_SWEEP_TOOLS="WebSearch,WebFetch,Read,Write,Bash,Agent"

NEW_ARGS+=(--tools "$SPAR_SWEEP_TOOLS" --allowedTools "$SPAR_SWEEP_TOOLS" \
           --strict-mcp-config --model "$DIRECT_MODEL" --safe-mode)

export PATH="$CLEAN_PATH"                 # own directory stripped, so it cannot recurse
export CLAUDE_PATH="$REAL_CLAUDE"
export NODE_OPTIONS="${NODE_OPTIONS:-} --require $UNDICI_PRELOAD"
export BUN_OPTIONS="${BUN_OPTIONS:-} --require $UNDICI_PRELOAD"
export ANTHROPIC_BASE_URL="http://127.0.0.1:11434"
export ANTHROPIC_AUTH_TOKEN="ollama-local"
export API_TIMEOUT_MS="${API_TIMEOUT_MS:-5400000}"
export CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS="${CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS:-5400000}"
export CLAUDE_BYTE_STREAM_IDLE_TIMEOUT_MS="${CLAUDE_BYTE_STREAM_IDLE_TIMEOUT_MS:-5400000}"

exec "$REAL_CLAUDE" "${NEW_ARGS[@]}"
```

## Why each piece is there

`--tools` governs which tool definitions are sent, which is what costs tokens. `--allowedTools` grants permission to call them. Both are needed: with `--permission-mode dontAsk`, which the dispatcher passes, a declared but unpermitted tool is refused outright. The wrapper also strips whatever `--allowedTools` and `--disallowedTools` the caller sent, because the dispatcher's own lists enlarge the request rather than shrinking it.

`--safe-mode` drops the operator's session-start injection and the repository's instruction files, which together were 19,668 tokens of a 26,608-token request. This is the single largest saving available.

`--model` is forced because no cloud alias maps to a local model name.

The base URL is ollama's bare origin with no path suffix. Ollama speaks the Anthropic Messages API natively, so no router is needed, and the CLI appends the path itself. Adding `/v1` produces a doubled path and a 404. The auth token can be any non-empty string; the endpoint does not check it, but an empty value sends the CLI into an interactive login.

`BUN_OPTIONS` carries the preload because the binary is Bun-compiled and ignores `NODE_OPTIONS`. Both are set so the wrapper keeps working if the binary changes runtime. Verified by pointing each at a script that throws unconditionally: under `BUN_OPTIONS` the process dies, under `NODE_OPTIONS` it prints its version and exits clean.

The preload nevertheless does nothing for the timeouts it was written for, and anyone rebuilding this should know that before trusting it. It calls `setGlobalDispatcher` on `undici`. The runtime is Bun 1.4.3, whose `fetch` is native and is not undici's: probed inside the same process, `globalThis.fetch` reports as native code and compares unequal to `undici.fetch`. Configuring undici therefore governs nothing the CLI sends. The preload loads, succeeds, and is inert.

Of the three timeouts, only `CLAUDE_BYTE_STREAM_IDLE_TIMEOUT_MS` governs the failure that mattered, an idle timeout on the byte stream tripped by the silence prefill produces. `API_TIMEOUT_MS` governs the client's patience with its endpoint. `CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS` is named for exactly this behaviour and has no effect here. A near neighbour, `CLAUDE_STREAM_IDLE_TIMEOUT_MS`, supplies a fallback floor only when the byte-stream variable is absent.

The `exec` passes the caller's arguments through an array, untouched. An earlier design handed them to a router which rebuilt the command line through a shell without escaping, and any prompt containing an apostrophe or a bracket died with a syntax error before the binary ran.

## The rest of the setup

Ollama runs on a separate machine, bound to localhost, reached through an SSH tunnel on port 11434. That tunnel has no supervisor: if it dies the bridge loses the model silently, and the symptom looks like an unreachable model.

The preload beside the wrapper resolves `undici` from the bridge's own `node_modules`, installed as a declared dependency, having previously borrowed it from an unrelated global package's internals. What it raises is undici's timeouts, which the Bun runtime does not consult, so the file is currently doing no work. It is kept because it is correct under Node and the binary's runtime is not ours to fix.

Set the model server's keep-alive long enough to outlast a run. It unloads an idle model after five minutes by default, and a reload costs tens of seconds before it can accept anything.
