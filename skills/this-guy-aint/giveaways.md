# giveaways

The ways belief breaks when a text claims an identity its author does not inhabit. The judge reads first and classifies after: these categories name the common breaks so a felt wrongness can be reported precisely, not a checklist to hunt with. A giveaway that fits no category is still a giveaway; report it as `other` and describe it. The two closing categories, secretary and officialese, are the exception to felt-first: they name a register that reads as competent and courteous and so trips no felt read; the judge checks the draft against those two deliberately, as its prompt directs.

The author's goal is never the impersonation; it is the work, done in that identity, without leaking that a non-member did it. Every category below is therefore a leak — something present in the text that a member would not have produced. The absence of persona is not a leak: plain, unadorned, workmanlike text with no opinions and no flavour is fully believable, because members write that way all the time. Never report what the text failed to perform; report only what it let slip.

Each category carries the question that detects it. The unit of evidence is always a quoted passage and what a real member would have done in its place.

## costume

The identity worn as decoration: slang density, stereotype props, self-announcement, performed at the reader rather than assumed. Real members signal through defaults — what they take for granted, what they skip — not through display; a member among members has nothing to prove and does not perform membership.

Question: is the identity shown by what the author assumes, or told by what the author wears?

Example: an email between two Melbourne tradies that opens "G'day mate! Hope you're having a ripper of a day down under" is written by someone playing an Australian at an audience. A real one writes "Mate, the quote for the Carlton job's attached" and the country never comes up.

## tourist

Vocabulary about the field rather than of it: the textbook or outsider term where the trade has a shop word, or shop slang that is real but wrong — dated, wrong region, wrong subfield. The words are correct the way a phrasebook is correct.

Question: are these the words members use to each other, or the words used to describe members?

Example: a developer's note that says "I utilized the version control system to revert the erroneous modification" is a tourist; the trade says "reverted the bad commit". A chef who "applied heat to the pan until the oil reached temperature" has never called the pass.

## overglossing

Explaining what every member already knows. The exposition level betrays the true audience: a text supposedly by a member for members that glosses the basics is written by an outsider proving the basics, or for one. In code, the comment that explains a language idiom any working developer reads without help.

Question: would the claimed author bother to say this to the claimed reader?

Example: a comment reading `// increment the counter by one` above `count++`, or a manager's memo that pauses to define what a one-on-one is.

## wrong-remark

Notices the wrong things. What the author finds remarkable is what a member finds mundane, and what a member would seize on passes without comment. Emphasis and excitement sit in the wrong places even when every fact is right.

Question: would a member's eye have landed here?

Example: an artist's studio note marveling that oil paint takes days to dry, while mentioning in passing a gallery taking sixty percent — the commission is the thing a working artist would lead with, the drying time is weather.

## register

Effort or formality mismatched to the artifact. Members calibrate to the occasion without thinking: a code comment is terse, a Slack answer is loose, a board memo is dressed. The impostor writes everything at one polish level, so the two-line comment arrives in press-release prose and the quick reply reads like an essay.

Question: is this the amount of effort a member would spend on this artifact?

Example: a commit message reading "This commit introduces a comprehensive enhancement to the authentication flow, ensuring robust handling of edge cases" — a developer writes "fix auth retry on expired token" and goes home.

## texture

Uniform rhythm — the load-bearing check for `human`. Sentences of even length, lists groomed to three, every clause resolved, nothing elided, no asymmetry, no sentence that trails off because the reader can finish it. People are uneven: they compress what bores them, dwell where it hurts, leave the obvious unsaid.

Question: does the surface vary the way attention varies?

Example: a trip report where every day gets one tidy paragraph of three sentences, each opening with the day's name. A person gives the food poisoning two pages and dismisses an entire city with "Tuesday was Geneva".

## certainty

Confidence inverted. A member is casually sure of the everyday and careful about the genuinely contested; the impostor hedges the mundane ("this may potentially improve performance" of an obvious cache) and pronounces on the disputed ("the correct architecture is X"). The hedges land where the author's knowledge is thin, not where the field's is.

Question: do the hedges sit where a member's doubts actually live?

Example: a supposed GP's note that says paracetamol "may be considered as a possible option" for a headache but states a definitive cause for a patient's chronic fatigue. A real one shrugs at the first and hedges the second.

## secretary

The pragmatics of a service role where a peer's voice was claimed. A peer has standing and face; staff have neither, so their social moves cost nothing, and the costlessness is the leak. Labels grade the author's own output — "finalized", "comprehensive", "enhanced", the past participle that certifies the author's own fix worked; "revised" says it changed, the grading word says it succeeded, and a peer states the delta and lets the reader judge. Courtesy grants the reader time or ease nobody asked for ("no hurry", "take your time", "hope this helps") — distinct from a personal remark reacting to the person, which is peer warmth. The close offers further service ("just say the word and I'll take another pass"); a peer takes the pass or doesn't. Admissions arrive frictionless: a peer who concedes ignorance or error pays for it and marks the payment ("I had to admit", "embarrassingly"); staff concede flatly, because nothing is at stake for them. Deliverables are inventoried for a client — a heading in the shape of "What each change does:", then items narrating what the author built — where a colleague names the problem or the symptom and lets the artifact carry its own mechanism. Co-recipients are managed by name mid-text the way a chair runs a meeting: telling Dana about Dana's own commit, thanking by name, granting by name. The name itself is not the leak — a peer uses one to ask or to react; the chair uses it to inform people of their own affairs and to dispense acknowledgement.

Question: is the author doing their own work among peers, or presenting finished work to a principal?

Example: a pull-request description that ends "happy to split this into smaller commits if preferred" — a peer splits it or doesn't. A status mail whose middle says "Priya, your migration already handles the enum case" — Priya knows what her migration handles; a colleague writes "Priya's migration already handles the enum case" and moves on.

## officialese

Sentence machinery no one uses when speaking as themselves. Nominalizations and clefts displace the first person: "the comparison of the traces is what isolated the fault" where a person says "I diffed the traces and found it". Bookish connectives and Latinate picks stand where a plain word exists: "thereby", "moreover", "prior to", "subsequently", "utilize", "which precedes the migration" for "before the migration" — the ordinary speech-relative ("which is why I held it") is not this; the test is whether the claimed author would say the word across a desk. A technical justification twenty or thirty words long sits inside parentheses between one verb and the next, and the sentence carries on after the bracket closes; a person breaks the sentence, or moves the justification to a footnote or its own paragraph. Deliverables are introduced by their own filenames — "02-retry-backoff.patch adds jitter to the retry loop", item after item down a list — where a person names the problem and lets the file carry its own name. Pointing is not the leak: a commit hash that locates a change, a test name with its tally, an error string quoted as evidence are how members point at things; the leak is the artifact's catalog name doing the work of saying what was wrong.

Question: is the sentence built the way the claimed author would say it out loud?

Example: a postmortem line reading "The examination of the deploy history is what surfaced the regression, which precedes the migration" — a person writes "I went through the deploy history and found the regression; it was there before the migration". A release note reading "the uploader now resumes interrupted transfers (each chunk carries a rolling checksum and the manifest records the last acknowledged offset, so the server can replay from that point) and deletes its temp files on completion" — a person ends the sentence at "transfers" and gives the checksum scheme its own line.
