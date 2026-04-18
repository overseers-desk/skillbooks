# Browser override — this campaign only

**Scope:** applies to any LinkedIn fetch subagent working in this campaign directory. Does NOT modify the user-level `~/.claude/CLAUDE.md`.

**Rationale:** the default headless command in `~/.claude/CLAUDE.md` targets `chromium` (snap-installed) against its snap profile `$HOME/snap/chromium/common/chromium`, which is logged in as **Chris Graham**. For a second discovery pass from Weiwu Zhang's 1st-degree network, use Weiwu's `google-chrome` profile instead.

## Exact invocation for this campaign when fetching LinkedIn as Weiwu

```bash
flock /tmp/google-chrome.lock timeout 30 google-chrome \
  --headless=new \
  --dump-dom \
  --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" \
  --user-data-dir="$HOME/.config/google-chrome" \
  --window-size=1280,800 \
  "URL" > out.html
```

## Rules

- Binary: `google-chrome` (not `chromium`). `which google-chrome` → `/usr/bin/google-chrome`, NOT a snap symlink.
- Profile: `$HOME/.config/google-chrome`, NOT the snap path.
- Lock: `/tmp/google-chrome.lock`. Different from the chromium lock so both can run in parallel if needed (they are different binaries with different profiles, no actual collision risk).
- Flags are otherwise identical to the CLAUDE.md chromium pattern: `--headless=new`, no `--virtual-time-budget`, UA override to defeat `HeadlessChrome` detection.
- Verification: the first fetch should produce a DOM whose `<title>` contains `Feed | LinkedIn` (not "Sign In") and whose JSON payload contains `"firstName":"Weiwu"` / `"lastName":"Zhang"`. If instead the title contains "Sign In" or the firstName is different, stop — do not proceed with a broken profile.

## When to use chromium vs google-chrome in this campaign

- `chromium` + `$HOME/snap/chromium/common/chromium` → Chris's LinkedIn identity (all 1A/1B/2B searches earlier in the campaign used this).
- `google-chrome` + `$HOME/.config/google-chrome` → Weiwu's LinkedIn identity (this second discovery pass; tag rows with `discovered_via=weiwu-1st-degree` or `weiwu-2nd-degree`).

Do not mix profiles in a single subagent run — each subagent should use one profile and tag its rows accordingly.

## HTML archive — mandatory

Every headless fetch in this campaign MUST save the fetched HTML to a persistent archive before any parsing. The archive lives at `./html-archive/` relative to the campaign directory and is gitignored.

**Path:** `html-archive/{YYYY-MM-DD}/{query-or-profile-slug}-{HHMMSS}.html`

- `query-slug` is the `action` column from `search-log.tsv` (e.g. `v2-tier2-ceo-hospitality-au-p0`) for search-result pages.
- For an individual profile fetch, use the LinkedIn URL slug (the `/in/{slug}/` portion).
- Timestamp to the second, to disambiguate re-fetches of the same URL.

**Invocation pattern:** always write through the archive, never dump-to-stdout-and-pipe. Parse from the archived file, not from the live DOM stream.

```bash
mkdir -p html-archive/$(date +%Y-%m-%d)
out=html-archive/$(date +%Y-%m-%d)/${slug}-$(date +%H%M%S).html
flock /tmp/chromium.lock timeout 30 chromium \
  --headless=new --dump-dom \
  --user-agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36" \
  --user-data-dir="$HOME/snap/chromium/common/chromium" \
  --window-size=3840,2160 \
  "$URL" > "$out"
# Then parse $out — not a pipe.
```

**Why this is mandatory.** On 2026-04-18 the tier-2/3 search subagent streamed 108 LinkedIn pages to `/tmp/linkedin-v2-t23-*.html`, parsed them in-process, and wrote 315 rows to `roster.tsv`. `/tmp` was cleaned after the session; ~132 of the 315 rows were parse-corrupt (Spanish UI strings in the organisation field, LinkedIn URL slugs appended to contact names, adjacent-row name bleed). Because the HTML was gone, re-parsing with a fixed parser was impossible — only re-fetching. Parser bugs recur in different forms; keeping the raw HTML is the only cheap insurance against the next one.

**Locale defensiveness.** Chris's LinkedIn *account* (not browser) is set to Spanish, so LinkedIn renders UI chrome as `contactos más en común`, `seguidores`, `Sídney y alrededores`, `Anterior`, etc. No `--lang` or `Accept-Language` flag overrides a logged-in user's account language — this is a LinkedIn account setting. Parsers that extract fields from the DOM must therefore:

1. Never accept an `organisation` value that matches a Spanish-UI lexicon (`seguidores`, `contactos`, `común`, `alrededores`, `mutuos`, `Anterior`, `Siguiente`, `grado`, `conexiones`).
2. Never accept a `contact_name` that ends with the LinkedIn URL slug (e.g. `Troy Clarry 8032339`).
3. Anchor field extraction to a single result-card DOM node per row; do not walk parallel selector lists that can drift out of alignment.
4. Reject any row where `contact_name` tokens share no prefix with the stem.

If Chris is willing, changing his LinkedIn account language to English would eliminate class (1). Until then, the parser carries the burden.
