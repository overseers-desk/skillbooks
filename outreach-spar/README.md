# SPAR — Search, Profile, Approach, Revise

AI-executed outreach methodology for discovering contacts, researching them, and writing personalised messages. Each phase has a procedure document that AI agents read and follow during dispatch.

## Directory layout

```
outreach-spar/
  spar-methodology.md          Methodology overview (all four phases)
  spar-S-search.md             S-phase procedure (sweep, roster building)
  spar-P-profile.md            P-phase procedure (contact research, dossier)
  spar-A-approach.md           A-phase procedure (drafting, A2 sparring)
  spar-roster-format.md        Roster TSV schema and quality checklist
  spar-campaign-yaml.md        Campaign YAML schema
  spar-campaign-directory.md   Campaign directory structure
  spar-segment-categorisation.md  Segment merge/split guidance
  spar-manager/                Tcl dispatcher, state machine, CLI, GUI
```

## How dispatch works

The dispatcher (`spar-manager/lib/spar-dispatch.tcl`) reads `campaign.yaml`, identifies contacts eligible for the next pipeline stage via the state machine (`spar-manager/lib/spar-state.tcl`), and launches AI agent sessions. Each session receives the relevant methodology document (e.g. `spar-P-profile.md`) as part of its prompt. The agent follows the procedure; it does not call scripts.

Post-assembly guard rails (`spar-manager/spar-a-harness.tcl`) validate the approach YAML and resume the agent with the errors until it passes or retries run out.

## Quick start

See `spar-manager/README.md` for CLI and GUI usage, dependencies, and test commands.

## Migration note

Legacy Python/Bash scripts formerly in `bin/` were replaced by the Tcl implementation in `spar-manager/`. The pre-removal state is preserved at tag `v0.1-pre-tcl-migration`.
