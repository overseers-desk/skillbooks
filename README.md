# AESOP

**AI-Executed Standard Operating Procedures**

SOPs written for AI agents to follow autonomously. These are not documentation for humans — they are instructions an AI reads and executes.

## Structure

- `travel/` — Travel planning and itinerary management
- `tests/` — Test cases and results for validating SOPs through iterative rounds
- `articles/` — Lessons learned from building and testing AESOPs
- `roster/` — Roster management research
- `sop-authoring-rules.md` — Meta-guide for creating and updating SOPs
- `aesop-authoring.prompt` — Prompt for AI-assisted SOP authoring with built-in testing methodology

## Usage

SOPs are executed by passing them to Claude as a prompt file:

```bash
claude -p travel/sop-travel-master.md
```

The master SOP orchestrates sub-SOPs as needed. Each SOP reads its inputs, performs its task, and produces outputs — no human in the loop.
