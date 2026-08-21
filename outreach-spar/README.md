# SPAR — Sweep, Profile, Approach, Revise

AI-executed outreach methodology for discovering contacts, researching them, and writing personalised messages. Each phase has a procedure document that AI agents read and follow during dispatch.

## Directory layout

```
outreach-spar/
  INVARIANTS.md                Hard rules; the rest of the methodology may not contradict them
  arch.md                      Why the pipeline is built this way, and what each choice cost
  spar-methodology.md          Methodology overview (all four phases)
  spar-S-sweep.md              S-phase procedure (sweep, roster building)
  spar-P-profile.md            P-phase procedure (contact research, dossier)
  spar-A-approach.md           A-phase procedure (drafting, A2 sparring)
  spar-roster-format.md        Roster TSV schema and quality checklist
  spar-campaign-yaml.md        Campaign YAML schema
  segment-schema.yaml          Segment definition YAML schema
  spar-campaign-directory.md   Instance layout, and which document owns each realm of facts
  spar-segment-categorisation.md  Segment merge/split guidance
  spar-version-uplift-runbook.md  Migrating an instance to the current spec generation
  spar-manager/                Tcl dispatcher, state machine, CLI, GUI
  experiments/                 Run data from model and host comparisons; not part of the spec
```

## How dispatch works

The dispatcher (`spar-manager/lib/spar-dispatch.tcl`) reads `campaign.yaml`, identifies contacts eligible for the next pipeline stage via the state machine (`spar-manager/lib/spar-state.tcl`), and launches AI agent sessions. Each session receives the relevant methodology document (e.g. `spar-P-profile.md`) as part of its prompt. The agent follows the procedure; it does not call scripts.

Post-assembly guard rails (`spar::ApproachHarness` in `spar-manager/lib/spar-harness.tcl`) validate the approach YAML and resume the agent with the errors until it passes or retries run out.

## Quick start

See `spar-manager/README.md` for CLI and GUI usage, dependencies, and test commands.
