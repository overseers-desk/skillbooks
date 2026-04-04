# AESOP

**AI-Executed Standard Operating Procedures**

SOPs written for AI agents to follow autonomously. These are not documentation for humans — they are instructions an AI reads and executes.

## Structure

### Methodologies

- `outreach-spar/` — SPAR: outreach discovery and engagement (Search → Profile → Approach → Revise)
- `correspondence-tend/` — TEND: correspondence processing (Thread → Evaluate → Notify → Dispatch)
- `listing-sift/` — SIFT: listing evaluation and response (Sweep → Investigate → Fit → Target)

### Reference methods

- `linkedin-lookup-method/` — LinkedIn profile lookup via headless browser
- `facebook-lookup-method/` — Facebook profile lookup via headless browser

### Other

- `travel/` — Travel planning and itinerary management
- `events/` — Event discovery and tracking
- `almanac/` — Event almanac and calendar
- `roster/` — Roster management research
- `articles/` — Lessons learned from building and testing AESOPs
- `tests/` — Test cases and results for validating SOPs through iterative rounds
- `sop-authoring-rules.md` — Meta-guide for creating and updating SOPs
- `aesop-authoring.prompt` — Prompt for AI-assisted SOP authoring with built-in testing methodology

## Usage

SOPs are executed by passing them to Claude as a prompt file:

```bash
claude -p travel/sop-travel-master.md
```

The master SOP orchestrates sub-SOPs as needed. Each SOP reads its inputs, performs its task, and produces outputs — no human in the loop.
