---
name: corpus-management
description: "Saving, reading or searching text captured in bulk, or meeting a corpus/ folder or *-pages.tar.zst archive: read this first. Triggers: corpus, scrape, crawl, fetched pages, raw HTML, search dump, fetch log."
---

# Corpus management

A corpus is text captured in bulk and kept as it was captured: fetched or scraped web pages, a site crawl, search-result dumps, listing reviews, threads exported from a mailbox. Where it came from does not matter. What makes it a corpus is that nothing in it is edited after capture; a fresh capture is a new dated record beside the old one.

Kept as loose files, a corpus costs a repository twice. Git carries every page into every clone. A grep for anything returns mostly corpus, so an agent looking for one document fills its context with captured pages. This skill keeps each corpus as dated zstd archives: grep and ripgrep see only compressed bytes, and git stores a new fetch as little more than its new pages. Text needed on purpose is reached through the commands below.

Documents people write and go on editing are not corpora, even when they quote one: coded records, findings, profiles. Nor are structured feeds read by scripts as tables, or files a repository rule says to keep exactly as they are.

## The layout

A corpus lives in a folder named `corpus/`, beside the work that uses it. The name is reserved: a `corpus/` folder holds this layout and nothing else, and notes about a corpus sit next to it, not in it.

```
corpus/
  2026-09-03-pages.tar.zst               one fetch; members <unit>/NN.md; committed
  2026-09-03-fetch-log.tsv               one row per page; committed
  2026-09-20-0100-pages.tar.zst          a second fetch on one date takes its start time
  2026-10-09-snapshot.tar.zst            a whole rebuild, superseding every older archive here
  .gitignore                             raw/  extracted/  staging/
  raw/<stem>/<unit>/NN.html              originals with their real extension; ignored
  raw/<stem>/...                         the fetch's by-products (logs, notes); ignored
  extracted/<unit>/NN.md                 written by corpus-unit for reading; ignored
  staging/<unit>/NN.md                   where a producer writes before corpus-add; ignored
```

The ignore rules sit in each `corpus/` folder's own `.gitignore`, because grep and ripgrep read an ignore file only in the folders they walk through: a rule at the repository root fails for a search started below it.

An archive's stem is its name less `-pages.tar.zst` or `-snapshot.tar.zst`: the fetch date, then optionally a start time and a label (`2026-09-20-0100-refetch`). Its fetch log is `<stem>-fetch-log.tsv`. A fetch that yielded only originals has a log and no archive.

`<unit>` is the key the work already uses for one source: a profile slug, a unit ID, a website domain, a query, a thread id. It may contain `/` (`rivals/<slug>`). `NN` is the page's order within its unit and fetch, two digits.

A member is YAML front matter, one blank line, then the captured text byte for byte:

```
---
url: "https://..."            "" when not recorded
fetched: "2026-09-03"         fetch date
fetched_source: "fetch-log"   where that date came from (fetch-log, folder-name, file-mtime, corpus-add)
http: "200"                   status, when recorded
raw: "raw/2026-09-03/<unit>/01.html"   the original, when there is one
former_path: "data/..."       where the text lived before it was archived, for old citations
archived: "2019-05-01"        Internet Archive snapshot date, for snapshot pages only
---

<the text>
```

A field that does not apply to the source stays blank or absent. A structured capture kept as fetched, with no text extracted from it, is a `<unit>/NN.json` member with no front matter.

The fetch log has one header row and the columns `unit, NN, url, http, bytes, sha256, raw, former_path, archived`. `bytes` and `sha256` are of the text below the front matter (of the original, when a page has no text). `former_path` holds the old text path and the old original path separated by `;`. A page whose original yielded no text has a log row and no member. The log is plain text on purpose: a grep for a URL or a unit finds it, and it holds no page content.

## How a corpus grows

**By generations**, for collections fetched from sources that change or disappear. Each fetch adds an archive; old archives are never rewritten. Within one `corpus/` folder, a member is read from the archive with the latest stem that holds it, so a later fetch of `<unit>/NN.md` replaces the earlier one. An empty member `<unit>/.wh.NN.md` in a later archive hides that page from earlier ones; that is how a source that has gone, such as an operator that closed, drops out of the current view. Archives in different folders never hide each other.

**By snapshot**, for a corpus rebuilt whole from a source the business holds, such as threads regenerated from a mailbox. A rebuild cannot name its deletions one by one, so a snapshot archive supersedes every older archive in its folder.

Stems compare as strings, which orders them by date, and within a date puts the untimed archive first and timed ones by start time.

## Commands

The commands sit in this skill's directory, `${CLAUDE_PLUGIN_ROOT}/skills/corpus-management/`. Each prints its usage when run without arguments.

| Command | Does |
|---|---|
| `corpus-add CORPUS_DIR [STAGING_DIR] [--snapshot] [--date D]` | Turns staged pages into the next archive and fetch log, moves originals and by-products to `raw/<stem>/`, empties staging, completes the `.gitignore`. Never replaces an existing archive. |
| `corpus-unit CORPUS_DIR UNIT` | Writes the current copy of a unit's pages to `extracted/<unit>/` and prints that folder, for reading whole with any file reader. |
| `corpus-grep [GREP-OPTION...] PATTERN ARCHIVE\|CORPUS_DIR...` | Greps the current copy of every page; prints `archive:member:line`. |
| `corpus-current [--unit UNIT] ARCHIVE\|CORPUS_DIR...` | Lists the current copy of each member, the selection the two readers use. |
| `corpus-check [ROOT]` | One line per `corpus/` folder: archives, growth, git state, and flags for loose files, a missing log, an incomplete `.gitignore`, pages left in staging. Exits 1 on any flag. |
| `corpus-raw push\|pull REMOTE:BASE CORPUS_DIR...` | Copies `raw/` originals to or from an rclone remote, mirroring each folder's path in its repository. Deletes nothing. |

They need GNU tar (`gtar` on macOS, `brew install gnu-tar`), zstd and Python 3; `corpus-raw` needs rclone.

## Adding pages

A producer, script or agent, writes into `corpus/staging/`: `<unit>/NN.md` for each page (front matter optional; `corpus-add` fills `url` and `fetched` when absent and sets `raw`), the original beside it as `<unit>/NN.<ext>`, `<unit>/.wh.NN.md` for a page that has gone, and anything else (logs, source lists) as by-products. Then the agent that ran the producer runs `corpus-add`. A script cannot run it on its own: `${CLAUDE_PLUGIN_ROOT}` exists only inside a session.

The archive's date is the fetch date: `--date`, else the earliest staged `fetched`, else today. A capture that ran past midnight is dated by its start.

Commit the archive and its log with the work that used them, and leave `raw/` to the mirror. Whether an archive holding personal data (customer correspondence, private individuals) is committed is the repository owner's decision; until it is made, the archive stays local, gitignored, in the same form.

## Reading and searching

A plain grep of the repository does not see inside the archives; that is the design. To read a unit, run `corpus-unit` and read the files it prints. To search, run `corpus-grep` over the corpus folders in scope. To find where a URL or unit appears, grep the fetch logs. A copy of page text written anywhere but `extracted/` is loose text again.

An old citation naming a former file path resolves through the fetch log's `former_path` column.

## Originals

Originals (HTML, PDF, the raw JSON a text was extracted from) are a cache: the archive is the record. `corpus-raw push` copies them to one remote folder so they survive a change of machine; `pull` fetches them on another. The repository names its remote, in its CLAUDE.md or INVARIANTS.md. Where it names none, ask the owner before pushing captured material to a cloud store.

## Checking

Run `corpus-check` from the repository root after adding to a corpus or converting one. Every flag is a departure from the layout above.

## Converting a loose corpus

Stage the existing files under their units as `NN.md` with front matter (`fetched` from a fetch log, a dated folder name or file time, saying which in `fetched_source`; the old path in `former_path`), run `corpus-add`, and compare every member's text with the file it came from before deleting anything. Rewrite the live pointers to the old paths (briefs, scripts, inventories) in the same commit; records of what was read (logs, coded tables, findings) keep their paths, which `former_path` resolves.

## Briefing another agent

Name this skill in the brief ("store and read the pages through the corpus-management skill"), not a command path: a path into the plugin is valid only on the machine that wrote it.

## Compatibility

The readers keep reading every archive this layout has produced: untimed and timed stems, labelled stems, fetch logs without an archive. A clone without this plugin still reads any page with `tar --zstd -xOf <archive> <unit>/NN.md`.
