# Outreach Personalization SOP

## Purpose

Given a target individual from the community roster, research what they've publicly said, determine which angle of the foundation's work is relevant to them, and draft a personalized outreach message. The output is a message ready for human review before sending.

## When to use

- When preparing outreach to individuals identified in the community roster
- When a new contact is identified at a conference, in a thread, or via referral and needs a personalized first touch
- When batch-preparing outreach messages for a segment

## Input

- **Target**: Name and whatever is known (from the roster, a URL, or a brief description)
- **Tier**: Which membership tier this person maps to — Strategic ($25K corporate), Corporate ($5K), Community (free), or Influence (regulator/policy, not a membership target)
- **Working directory**: The opensource.foundation project directory, which contains the foundation's published materials

If no tier is specified, infer from context. An individual maintainer or researcher is Community. A person with "VP", "Head of", "Director" at a company is Corporate or Strategic. A government/regulator staffer is Influence.

## Output

A markdown file saved to `outreach/drafts/[name-slug].md` containing:

1. **Research summary**: What this person has publicly said or done that's relevant
2. **Angle**: Which of the foundation's offerings connects to their known interests
3. **Draft message**: A short, personalized email or LinkedIn message
4. **Contact method**: How to reach them (email if public, LinkedIn profile if found)

## Data sources

The SOP draws on these. Read them before drafting.

| Source | Where | What it tells you |
|---|---|---|
| Community roster | `outreach/community-roster.md` | What each person said publicly and where |
| Direct outreach pipeline | `outreach/direct-outreach-pipeline.md` | Segment priorities, conversion assumptions, messaging emphasis by tier |
| Foundation mission | `site/content/en/about/mission.md` | What the foundation does — provenance certification, AI model provenance, compliance services, jurisdictional independence |
| Provenance certification | `site/content/en/projects/provenance-certification.md` | The core offering in detail |
| Cross-jurisdictional licensing | `site/content/en/projects/cross-jurisdictional-licensing.md` | The licensing working group |
| Foundation story | `site/content/en/about/story.md` | Origin, motivation, XZ incident framing |
| LinkedIn lookup method | `~/code/weiwu/linkedin-lookup-method/README.md` | How to find someone on LinkedIn using headless Chromium |

Do not read all of these every time. Read the roster entry for the target first, then read whichever foundation documents are relevant to the angle you're going to use.

## Procedure

### Phase 1: Research the target

**1.1 Check the roster**

Look up the target in `outreach/community-roster.md`. If they appear, note:
- What they said and where they said it
- Which section they're in (this reveals their community — oss-security contributor, NixOS participant, OpenSSF leader, etc.)

**1.2 Web search for recent activity**

Search for recent public statements, blog posts, conference talks, or social media activity. People's positions evolve. The roster captures what they said in 2024; they may have published something more recent.

Search: `"[Name]" open source security 2025 OR 2026`
Search: `"[Name]" supply chain provenance`

If nothing recent turns up, the roster entry is sufficient.

**1.3 LinkedIn lookup (if contact info needed)**

Follow the method in `~/code/weiwu/linkedin-lookup-method/README.md`. This requires headless Chromium with the user's user-data-dir. Check that Chromium is not running before attempting.

LinkedIn is for finding contact details and current role. Do not spend time on LinkedIn if you already have what you need from the roster and web search.

**1.4 Identify the angle**

Based on what the target has said, determine which of these angles connects:

| Angle | When to use | Foundation offering |
|---|---|---|
| **Certification gap** | Target has written about provenance, SLSA, Sigstore, or supply chain attestation — they build tools but nobody audits | Provenance certification as the independent verification layer |
| **Jurisdiction** | Target has discussed geopolitical risks, sanctions impact on open source, or cross-border trust | Singapore domicile, jurisdiction-neutral certification |
| **Transitive provenance** | Target has discussed dependency chains, XZ-style attacks, single-maintainer risk | Transitive provenance certification — certificates that propagate through the dependency tree |
| **CRA/regulation** | Target works at or with an EU company facing Cyber Resilience Act compliance | Compliance services, CRA guidance |
| **Cross-border licensing** | Target deals with Chinese-Western open source collaboration or IP law differences | Cross-jurisdictional licensing working group |
| **AI provenance** | Target works on AI model governance, training data lineage, or model transparency | AI model provenance working group |
| **Maintainer sustainability** | Target has written about burnout, under-resourced maintenance, or funding gaps | Provenance certification as a way to make maintainer risk visible and drive support |
| **Network / connection value** | Target has no direct engagement with the foundation's technical themes, but occupies a network position that connects to people, organisations, or communities the foundation needs to reach — conference organisers, community bridge figures, people with operational relationships in target geographies (China, ASEAN, EU) or target sectors (fintech, government tech, AI governance) | Advisory board candidacy, community connector role, conference partnership, introductions to specific organisations or communities. The ask is not membership or working group participation — it is a relationship that opens doors. |

Most targets from the roster will map to "certification gap" or "transitive provenance" since they wrote about XZ and supply chain trust. The angle should feel like a natural extension of what they already care about, not a sales pitch for something unrelated. Targets whose primary value is network/connection may have no engagement with the foundation's technical themes at all — what matters is who they know and what communities they operate in, not what they have said about provenance or compliance.

### Phase 2: Draft the message

**2.1 Read the relevant foundation documents**

Based on the angle, read the corresponding project page. Do not quote it verbatim — understand it well enough to reference naturally.

**2.2 Draft**

The message should be:
- **Short**: 4–8 sentences for email, 2–4 for LinkedIn. Nobody reads long cold messages.
- **Specific**: Reference something the target actually said or built. This is why the research phase exists.
- **Clear ask**: What do you want from them? For Community tier, it's "join a working group" or "submit a letter of support." For Corporate, it's "let's talk about how this applies to your organisation." For Influence, it's "we'd value your input on our approach."
- **No jargon about the foundation**: Do not lead with the foundation's structure, governance, or Singapore domicile. Lead with the problem the target cares about and how the foundation's work connects.

**2.3 Structure**

```
Subject: [Something specific to them, not generic]

[One sentence connecting to what they've said/done.]

[One sentence describing the gap the foundation addresses — in terms they'd recognise.]

[One sentence about the foundation — what it is, briefly.]

[The ask — specific, low-friction.]

[Sign-off]
```

For Community tier, the ask is joining a working group or providing a letter of support. For Corporate, the ask is a 20-minute call. For Influence, the ask is reviewing a draft paper.

**2.4 Tone**

Write as a peer, not as a marketer. The target is a practitioner who has thought deeply about this problem. The message should read like it was written by someone who has also thought deeply about it and wants to collaborate, not sell.

Do not use:
- "I hope this message finds you well"
- "I was impressed by your work on..."
- "We are excited to announce..."
- Marketing superlatives

Do use:
- Direct reference to their specific contribution
- The problem framing they would recognise
- A concrete next step

### Phase 3: Save output

Create the output file at `outreach/drafts/[name-slug].md`:

```markdown
# Outreach: [Full Name]

## Research

**Known from**: [Roster section or how they were identified]
**What they said**: [Brief summary of their public position]
**Current role**: [If known]
**Recent activity**: [Anything found in web search, or "Nothing beyond roster entry"]

## Angle

[Which angle from Phase 1.4 and why it fits]

## Draft message

**Channel**: [Email / LinkedIn]
**Subject**: [Subject line]

[Message body]

## Contact

- Email: [if public]
- LinkedIn: [URL if found]
- Other: [Twitter/Bluesky/Mastodon if relevant]
```

### Phase 4: Batch mode

When processing multiple targets, group by angle rather than by roster order. This lets you read the relevant foundation document once and draft several messages with the same framing, adjusting the personal reference for each target.

Prioritise targets who expressed strong alignment with provenance certification over those who were neutral or skeptical. Skeptics are worth engaging but require more careful framing — lead with the part of their critique the foundation agrees with.

---

**End of Standard Operating Procedure**
