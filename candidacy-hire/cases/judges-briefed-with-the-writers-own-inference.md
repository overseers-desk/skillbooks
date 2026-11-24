# Judges briefed with the writer's own inference

**The situation.** Both efforts settled choices with sealed-room judges: a model briefed as a recruiter, shown versions of the candidate's text, asked to choose and to name one thing it would still fix.

**What the AI wrote.**
- For a post managing about thirty engineers at a cloud vendor, the brief left the judge to read the CV against the only advertisement it held, written for the level below; the judges rewarded that advertisement's words and its hands-on detail. A later brief added a sentence of the AI's on what the hiring manager hires for at this level, and that hands-on skill belongs to the level below, and named a first reader the AI had inferred. Under the first brief one pair of versions lost in every room; under the second, the same pair won in every room.
- For a research residency at an AI lab, the brief said research mentors chose whom to interview, showed only the CV and one answer, and said nothing of volume or of the form's other fields. The judges asked the motive answer for a research area, a hypothesis, named papers and a first project, and the AI added them. The forced fix line produced an ask in every room, and the AI read the count of asks as demand. A pool of rival applicants was written by the judging model from personas the AI chose, three told to be excellent; those three topped every run.

**What the candidate said.** "You don't tell the judge what our intention is. Just ask them to compare." If the judge keeps rewarding wiring, perhaps it does not know the level of the post. Was it told it screens hundreds of submissions? So the AI had made up the other applicants' answers? Why did the winners read like cover letters? The judges behaved like the rubric they were trained on, not like a recruiter.

**What it missed.**
- A brief that says what the reader values makes the result an echo of the brief. The AI conceded the flip partly measured its own sentence.
- A judge told that a mentor decides, and not told the form has a research field, reads a motive answer as a research proposal.
- Judges comparing versions of one candidate measure completeness, not standing out among hundreds.
- Rivals written to be excellent by the judging model confirm that model's taste.

**Instances.**
- The level-below brief, rewarding wiring.
- The brief that stated the reader's values and an inferred first reader.
- The mentor-facing brief that turned the motive answer into a proposal.
- No pool and no volume in the brief.
- The forced fix line read as demand, answered with added anecdotes and an apologetic sentence.
- The invented pool of rivals.

**The rule it produced.** `../hire-methodology.md`, H: "A judge's brief and a reader line carry what the advertisement and the candidate said; an inference put there comes back as the judge's finding." E 5, **Judges**: the brief holds the advertisement and what `hirer.md` marks as from the candidate or a named source; "A judge made to name one thing to fix will name one"; at least one version in a comparison was not written by this session. The brief is not yet told to carry the volume and the fields the real reader sees, where the candidate or the employer has stated them.

**To re-run it.** Give a fresh agent the methodology, an invented advertisement for a team lead, the candidate's word that the post sits two levels higher and that the recruiter screens about five hundred applications, and ask for the judge brief. It passes if the brief holds the advertisement and the candidate's two facts marked as his, and no sentence on what the reader values. Then run one pair with and without such a sentence: if the verdict flips, the sentence was deciding it.
