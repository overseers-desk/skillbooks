# Revival: CampaignBoard.tsx — D hub, B=0

**Instrument check first.** D is real: 14 distinct in-repo files imported (react,
react-query, @lingui excluded as libraries) — eight are `web/src/ui/*` kit primitives
(Board, Overlay, SelectableCard, CtxMenu, ReachNote, atoms, DeepLink, useCardSelection),
one is `web/src/lib/use-api-view`, five are sibling social-sphere modules (`api`,
`CampaignDelete`, `components`, `cards`, `drafts`). My D=2 assumed a board mostly draws on
its own api.ts; it missed that a kanban view pulls in one file per kit primitive. B=0 means
nothing about isolation: the vocabulary (`DraftChip`, `MemberCard`, `onReview`) is private
— those names are defined and used only inside this file, never exported, so the filter
had nothing to grep. It is the vocabulary floor, not a signal.

Reading the mechanism: the file's own content is `DraftChip`/`MemberBody`/`MemberCard`
(local render subcomponents) and `CampaignBoard` itself, whose logic is thin wiring —
`drag={{ onDrop }}` calls `flipStage` from `./api`, stage grouping calls `effectiveStages`
from `./api`, menu items come from `./cards`. The drag protocol lives in `Board.tsx`; stage
derivation lives in `api.ts`; there is no wizard state machine here (that's
`CampaignWizard.tsx`). Nothing is re-derived locally.

**Verdict: by design.**
