# Browser override: this campaign only

**Scope:** applies to any LinkedIn fetch subagent working in this campaign directory.

**Rationale:** the snap chromium user-data-dir `$HOME/snap/chromium/common/chromium` carries two LinkedIn-logged-in profiles. The `Default` profile is **Chris Graham**; the `Weiwu` profile is **Weiwu Zhang**. The `not-google-chrome` wrapper does not specify `--profile-directory`, so chromium falls back to `Default` (Chris). For a second discovery pass from Weiwu's 1st-degree network, select the `Weiwu` profile explicitly by passing `--profile-directory=Weiwu` as an extra flag after the URL.

## Exact invocation for this campaign when fetching LinkedIn as Weiwu

```bash
not-google-chrome -t 30 "URL" --profile-directory=Weiwu > out.html
```

## Rules

- Profile selector: `--profile-directory=Weiwu` for Weiwu, `--profile-directory=Default` (or omitted) for Chris. This is the only flag that distinguishes the two identities.
- Both profiles share one user-data-dir, so they cannot run concurrently. The wrapper's `flock /tmp/chromium.lock` serialises them on the same lock.
- Verification: the first fetch should produce a DOM whose `<title>` contains `Feed | LinkedIn` (not "Sign In") and whose JSON payload contains `"firstName":"Weiwu"` / `"lastName":"Zhang"`. If instead the title contains "Sign In" or the firstName is different, stop. Do not proceed with a broken profile.

## Which profile to use in this campaign

- `--profile-directory=Default` → Chris's LinkedIn identity (all 1A/1B/2B searches earlier in the campaign used this).
- `--profile-directory=Weiwu` → Weiwu's LinkedIn identity (this second discovery pass; tag rows with `discovered_via=weiwu-1st-degree` or `weiwu-2nd-degree`).

Do not mix profiles in a single subagent run — each subagent should pass one `--profile-directory` value and tag its rows accordingly.

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
not-google-chrome -t 30 "$URL" --profile-directory=Weiwu > "$out"
# Then parse $out, not a pipe.
```

**Why this is mandatory.** On 2026-04-18 the tier-2/3 search subagent streamed 108 LinkedIn pages to `/tmp/linkedin-v2-t23-*.html`, parsed them in-process, and wrote 315 rows to `roster.tsv`. `/tmp` was cleaned after the session; ~132 of the 315 rows were parse-corrupt (Spanish UI strings in the organisation field, LinkedIn URL slugs appended to contact names, adjacent-row name bleed). Because the HTML was gone, re-parsing with a fixed parser was impossible — only re-fetching. Parser bugs recur in different forms; keeping the raw HTML is the only cheap insurance against the next one.

**Parse structurally, not textually.** The 2026-04-18 corruption was not fundamentally a language problem — the chromium snap profile had been running under a Spanish locale at first LinkedIn sign-in, so LinkedIn persists a Spanish-rendering cookie for Chris's session, and UI chrome comes back as `contactos más en común`, `seguidores`, `Sídney y alrededores`, `Anterior`. But LinkedIn's DOM structure is language-invariant: class names (`entity-result__title-text`, `entity-result__primary-subtitle`, `entity-result__secondary-subtitle`), `data-test-*` attributes, and the card hierarchy are the same in every locale. The subagent that parsed tier-2/3 results was doing text-heuristic extraction — walking the flattened text of each card and guessing which substring was the name / organisation / role by order or by keyword — and those guesses broke systematically when the rendered text turned out to be Spanish UI chrome instead of English data.

Parsers that extract fields from the DOM must therefore:

1. Anchor on one result-card DOM node per row and extract each field from its structurally-defined slot (title-text span for name, primary-subtitle span for role/headline, secondary-subtitle span for location, etc.). Do not walk parallel text lists that can drift out of alignment and produce adjacent-row name bleed.
2. Never accept a `contact_name` that ends with the LinkedIn URL slug (e.g. `Troy Clarry 8032339`) — that is the stem concatenated onto the name, a textual-extraction artefact.
3. Reject any row where `contact_name` tokens share no prefix with the stem.
4. As a belt-and-suspenders sanity check against any unexpected locale rendering, refuse an `organisation` value that matches known UI-chrome phrases in any language (`seguidores`, `contactos`, `común`, `alrededores`, `mutuos`, `Anterior`, `Siguiente`, `grado`, `conexiones`, `followers`, `mutual connections`, `Previous`, `Next`, etc.).

Forcing a specific chromium locale (`LANG=en_US.UTF-8` env + `--lang=en-US` flag, or a fresh sign-in under an en-US locale to rewrite the cookie) is optional hardening. It is not load-bearing once the parser is structural.
