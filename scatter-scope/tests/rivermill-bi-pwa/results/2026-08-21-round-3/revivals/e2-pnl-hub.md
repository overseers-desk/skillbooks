# Revival: ProfitAndLoss.tsx — D hub

**Instrument check first.** D=19 is real, not artefact: the file's static imports are 18
distinct in-repo, non-CSS module files (react/react-dom/@lingui are libraries, correctly
excluded) — six `web/src/ui/*` kit widgets (SectionHeader, FreshnessNote, atoms, ReachNote,
Chips, FilterRow), four `web/src/lib/*` utilities (use-api-view, url-state, format,
download), and eight sibling sphere modules (api, matrix, window, vocab, export,
letterhead, period, PeriodPicker) — plus two CSS imports the estimate under-weighted. My
D=5 assumed a view mostly draws on its own api.ts; it missed that the sphere already
splits its domain logic into eight small owned modules, all pulled in here.

Reading the mechanism: local functions are `fmt`/`kfmt`/`money` (presentation formatting),
`parseSrc`/`serializeSrc` (URL codec for a Set), `NetRow`/`Statement`/`Kpi`/`Kpis`/
`ProfitAndLoss` (rendering). None of them re-derive what `matrix.ts` (month arithmetic),
`window.ts` (filtering), `period.ts` (date math), or `export.ts`/`letterhead.ts` already
own — the view calls into each, it doesn't hold their state or logic itself. High D is the
cost of a thin composition layer sitting over many single-purpose modules, not a subsystem
living in the wrong place.

**Verdict: by design.**
