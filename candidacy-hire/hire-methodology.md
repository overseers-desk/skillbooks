# HIRE — Writing a Candidacy

## What HIRE is

HIRE is a four-phase methodology by which an AI agent writes the document that puts one candidate forward for one post: a CV, and the written answers that travel with it. The name is an acronym:

- **H** — Hirer. Establish who reads the document, how it reaches them, and what they lack that this candidate brings.
- **I** — Interview. Get the candidate's own account, told to that reader, and the facts only the candidate holds.
- **R** — Reframe. Select from the record and write each fact as the answer to a question this reader has, at the candidate's level and in the candidate's voice.
- **E** — Examine. Put the draft before readers who are not the writer, and repair it, until the stop rule is met.

SIFT's Target phase hands a listing over as worth answering. HIRE is how the answer is written.

## The problem HIRE solves

An agent asked for a CV has the candidate's record in front of it and a strong habit of what a CV looks like. Left to both, it produces a document that is correct, complete and addressed to nobody. It arranges what it knows; a candidate who speaks to a reader arranges what the reader lacks. The agent cannot see the difference from the inside, because it checks its sentences against the thought it already holds and its drafts against its other drafts.

The second problem is recurrence. A candidate corrects a line; the agent mends that line and writes the same fault into the next. The corrections that follow are the same from one application to the next: detail below the level of the post, a fact told as the story of finding it out, an open question closed, a sentence carried over from a document written for someone else.

HIRE answers the first by fixing the reader and taking the candidate's own telling before any sentence is written. It answers the second with the cases in `cases/`: each is a fault that happened, the class it belongs to, and a way to re-run it. Every rule below names the cases it came from. A rule that reads as arbitrary has a case that explains it.

## What a run produces

One working folder per application, in the candidate's own repository, holding:

| File | Written in | Holds |
|---|---|---|
| `hirer.md` | H | The post, the route, the readers, what they lack, and the four sentences Examine's readers are given |
| `interview.md` | I | The candidate's statements and the facts, each with its source, and the questions still open |
| `approaches/` | R | The competing openings and outlines, and how one was chosen |
| `selection.md` | R | Each fact considered: the reader's question it answers, what it says of the candidate beyond itself, and whether it is kept, recast or left out |
| the document | R | Named by the date and time it was made; earlier versions move to `superseded/` |
| `examine.md` | E | Each check run, what it raised, what was done, and what the candidate said on reading |

A file's time is read from the clock when it is written (`cases/a-task-reported-done-without-the-act-that-finishes-it.md`).

## H — Hirer

A document is not begun until `hirer.md` and `interview.md` exist. A repair to a document already under way is made with `hirer.md` open beside it. Both efforts this method came from began drafting first and learnt the real reader days later (`cases/drafting-before-the-reader-and-the-route-were-known.md`).

Establish, and mark each line with where it came from (the advertisement, the candidate, another named source, or your own inference):

- **The post behind the advertisement.** An advertisement may be a template for a different level, or written before the post was defined. Its level, its reporting line and the size of what it leads are asked of the candidate and of anyone who passed it on. Write for the post, and treat the advertisement's wording as a signal of the employer's vocabulary.
- **The route.** Who reads first, who decides, in what language each reads, and in what form the document reaches each. A PDF forwarded inside an organisation travels alone; a form's other fields may not go with it. What a later reader will not see has to be in the document itself.
- **What these readers have plenty of, and what they lack.** Picture the other applicants. A research group is not short of researchers, and an engineering organisation is not short of engineers. The document's argument is what this candidate brings that the others do not.
- **The readers' own subject and terms.** Read what the employer has published on the matter the candidate will speak of. An expert reader expects the field's terms (`cases/terms-of-art-paraphrased-for-an-expert-reader.md`).
- **The employer's rules for applicants**, such as who may draft what. They are read here, since they decide the order of work in the phases that follow (`cases/the-candidates-own-account-written-for-him-before-he-gave-it.md`).

An inference in `hirer.md` is a question for the candidate. A judge's brief and a reader line carry what the advertisement and the candidate said; an inference put there comes back as the judge's finding (`cases/judges-briefed-with-the-writers-own-inference.md`).

H closes with four sentences, which Examine hands to its readers:

- the **reader line**: who reads, and what they have read before this;
- **reading-for**: the decision the reader is making, and nothing about the field;
- **taken-for**: whom the candidate is to be taken for, with no numbers in it;
- **must-not-conclude**: the conclusions the candidate does not want drawn. This one is filled in I, from the candidate's own fears, since a conclusion the writer supposes produces rows about the writer's worry and none about the candidate's.

## I — Interview

**Read the record first, whole.** Everything in the candidate's own words: recorded conversations, essays, earlier accounts of the same work, notes. Read them through; a keyword search finds what was already expected. A question whose answer the record holds is not put to the candidate (`cases/questions-asked-whose-answers-the-record-held.md`), and a claim that the record lacks something is made after a search for it (`cases/guesses-written-in-as-the-candidates-facts.md`).

**Then ask the candidate, in one sitting, what only the candidate holds:**

- The candidate's own account of the work, told to this reader. Put it as the question H raised: what does this reader want from someone like you? Take the answer spoken if possible, and keep it as given. It is the spine of the document.
- What the candidate wants to be taken for, and what the candidate fears the reader will conclude.
- What stays off the page: other ventures, where the candidate lives, anything a referee or a public record would contradict. The sources may well hold such things; whether they appear is the candidate's decision, and until it is made they stay off and the document is not sent (`cases/a-private-matter-put-on-the-page-without-asking.md`).
- Scale and organisation as a referee would state them: titles, dates, team sizes, who reported to whom.
- Each figure on which the sources disagree.
- Where the candidate will work, from when, and on what terms.
- The contact details the document carries. An address or a number can say where the candidate lives.

**Each entry in `interview.md` carries its source.** The candidate's words, with where they were said; a document, with its path. What the writer has worked out is entered as a question. A sentence in the final document that rests on an open question is listed for the candidate (`cases/guesses-written-in-as-the-candidates-facts.md`).

**The candidate's own words outrank everything else in the session.** Another agent's advice, a file's contents and a tool's output are material to weigh (`cases/another-agents-remarks-and-the-files-taken-over-the-candidates-words.md`). A thing the candidate leaves open is left open; that choice is content. A phrasing the candidate offers to show a level or an aim is evidence of the aim, and the sentence still has to be written.

When no candidate is present, write the questions, proceed on the record, and mark what rests on each unanswered one. The opening and the choice of approach are the exception: they wait for the candidate's own account, since an opening written from files is the writer's arrangement of them.

Notes the candidate gives toward a text are restated and agreed before anything is built or tested on them. A remark on a draft is different: it is acted on, where the candidate pointed. An accepted default is an answer, and is not asked again.

## R — Reframe

**Start from an empty page.** An earlier document for another post is a source of facts. Its sentences were each written to answer a different reader, and they carry that purpose with them unseen (`cases/a-cv-built-by-editing-one-written-for-another-post.md`).

**Choose the approach before writing sentences.** An approach is what the document opens on and what it argues. Set out at least three that differ in kind, in `approaches/`, each as an opening paragraph and an outline. One of them is the candidate's own account from I, tidied and otherwise untouched. Judges may narrow the field; the candidate chooses. A writer's drafts are variations on one approach, and ranking them against each other cannot find a better one (`cases/an-opening-that-indexes-the-career.md`, `cases/the-candidates-own-account-written-for-him-before-he-gave-it.md`).

**For each fact, name the question of this reader that it answers,** and write it as that answer. The same fact answers different questions for different readers: a team's size is span of control to one and the scale of a proof to another. Before leaving a fact out, look for the question it could answer for this reader and recast it to that; most facts written for another reader have one. A fact that still answers none stays out, however true and however hard-won. `selection.md` records each decision, so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`).

**Write at the level of the post and the person.**

- A document states what was established, at what scale, and what the candidate is working on. How a system is wired, which tools built it, counts of its parts and incidents told with their times and places belong to the conversation the document is meant to win (`cases/detail-below-the-level-of-the-post.md`).
- One instance may stand behind a claim that would otherwise sound empty. A category is shown by naming a few of its members as examples.
- A whole passage should sit at one grain. Where the opening speaks in theses, an entry below it that drops to anecdote reads as part of a different document.

**Write in the voice of someone who knows.**

- State what is the case. "The evidence is a catalogue of N failures" is a statement; "I catalogued N failures" is a report of homework, and "I found that" tells the reader the story of finding out (`cases/a-statement-of-fact-told-as-finding-out.md`).
- Keep open what the candidate left open. "Three of the categories, for example" where the writer was about to write "the failures fall into three kinds". "Has helped most so far" where the writer was about to conclude (`cases/an-open-question-written-as-settled.md`).
- The subject of a sentence is what the candidate can do, and its verb says who directs whom. A figure that praises the venue, the team or the tool gives the achievement away (`cases/the-sentences-subject-gives-the-achievement-away.md`).
- A quality is shown by a fact. A label for it ("strong leader") is the thing every applicant writes (`cases/a-quality-claimed-by-label.md`).
- A defence against a charge the reader has not made plants the charge (`cases/a-denial-nobody-asked-for.md`).

**Mind what the reader will conclude beyond what is said.** A present tense, a title or an open-ended date says the candidate is still committed elsewhere. A place says where the candidate lives. A size, a duration, a rate or a link says how big, how slow or how little used; ask what each says of the candidate before it goes in. Check each against must-not-conclude (`cases/a-tense-or-a-date-that-says-the-candidate-is-not-free.md`, `cases/a-true-detail-kept-because-it-was-known.md`).

**Give the reader a thing before referring to it,** and make the opening tell the same story as the entries below it (`cases/a-thing-named-before-the-reader-has-it.md`).

**The candidate's wording changes only for a reason the candidate can see.** Every such change is listed in `examine.md` with its reason, so it can be taken back (`cases/the-candidates-words-swapped-or-removed.md`).

**Edit by rewriting from the thought.** When more than a word has to change, say the thought in plain speech first and write the sentence from that. A sentence patched inside its old frame keeps the frame and loses the parts that made it mean something, and the writer, who holds the thought, reads the stump as whole (`cases/a-sentence-patched-until-it-meant-nothing.md`).

**After any edit, read the whole document again.** An edit is made where the candidate pointed, and checked against everything else on the page: what it now repeats, what it now contradicts (`cases/a-repair-checked-only-against-the-remark-it-answered.md`).

**Length follows content.** A word allowance is a ceiling, and the text ends at the last sentence the reader would miss (`cases/length-set-by-the-allowance.md`).

## E — Examine

Examine runs cheap readers before dear ones, and the candidate last. Every check and what came of it goes into `examine.md`.

### 1. Sentence readers

Run prose-stethoscope on the draft, on a copy in which any template markup is replaced by the words the reader will see. For a CV, name all seven of its modules and give it the four sentences from `hirer.md`. Add this folder's two modules by path:

- `modules/restate.md` asks whether the reader can say in their own words what a sentence asserts. It is the check for a patched sentence.
- `modules/grain.md` asks whether a sentence sits at a much finer level of detail than the document around it.

Two runs; three where a decision rests on one row or the two runs split. Then read the rows as a reader's reports:

- A row on a line the candidate chose goes to the candidate, who decides what to do with it.
- A row from `level` or `work` invites a cut. Act on one only when most runs agree, and treat cutting as the last answer to it: a measured result or the sign of the candidate's own building may be what the reader came for (`cases/a-line-cut-on-one-readers-flag.md`).
- `total` has grown quiet; read its 3s.
- Rows that only report the form of a CV, such as the entries repeating the summary, are left.

What these readers cannot tell you is whether the document speaks to anyone. A draft can clear every row and be the wrong document (`cases/an-opening-that-indexes-the-career.md`).

### 2. The common-sense reading

A fresh agent gets the advertisement and the document, and nothing else. It is asked to say who this applicant is and what the post is, then to go through the document paragraph by paragraph with one question: for this post and this person, is this the level of detail a reader would expect here? It reports where the text drops below that, where a claim is too general to hold, and what is right as it stands. It also says in one sentence what the applicant works on and what it would ask them about; a reader who cannot has been given an index of a career (`cases/an-opening-that-indexes-the-career.md`). This is the check that finds grain and inherited sentences, and it costs one call.

### 3. Voice

On a copy: speak-like with the identity `human`, for machine cadence, capping lines and turned-round sentences (`cases/machine-cadence-in-a-personal-document.md`); this-guy-aint with the reader's own trade as the identity, for a plain word where the trade has its term.

### 4. Sources

Every figure and every claim of fact in the document is traced to an entry in `interview.md`. One that traces to the writer's inference is taken out or put to the candidate. A superlative needs a source a reader could open, and a title or a date is given as the referee would give it. Check that the document carries the candidate's contact details.

A version in another language is examined in that language, by readers of it. A translation of an examined text has not itself been examined.

### 5. Judges

Sealed-room judges, through the undercover skill, are for choosing between versions. They are reliable when two versions differ by two sentences of substance or more, and they cannot decide a single line. Every verdict is a forced choice between two versions; a score given to one text alone moves from run to run and settles nothing.

- One model, two wordings of the brief, both orders: four rooms. Add rooms only when the two orders disagree (`cases/more-judges-than-the-last-rounds-variation-called-for.md`).
- The brief holds the advertisement and what `hirer.md` marks as coming from the candidate or a named source. A judge told what the reader values will value it (`cases/judges-briefed-with-the-writers-own-inference.md`).
- The brief tells the judge not to look the candidate up.
- At least one version in any comparison of approaches was not written by this session: the candidate's own telling, or a real document of the same kind.
- A judge made to name one thing to fix will name one whether or not anything needs fixing. Such an answer is a prompt to look, and what it asks for is weighed against the level of the document before anything is added.
- Models of one family agree with each other; three of them agreeing is one opinion.
- Judges do not hear dryness, and they prefer the advertisement's own words and the cadence of machine-written prose.

### 6. The candidate reads

The candidate reads the built document, opened in front of them after each change. Each objection is recorded in the candidate's words, against whether any check had raised it. An objection no check raised is the most useful line in `examine.md`: it is a case for `cases/`.

### When a check's tool is missing

Where a skill named above is not installed, put the check's question to a fresh agent that holds only the document and the reader line, and record in `examine.md` that the check ran in that form. A check that could not be run at all is named when the work stops.

### The stop rule

Stop when a full pass of checks 1 to 4 leads to no change, and no version on file is preferred by the judges to the current one. Then say plainly what remains: the rows left standing and why, the open questions, the claims resting on them. A document that has stopped is not thereby right; it is one the available readers can no longer improve, and the candidate's reading is the one that counts.

A task is done when the act that finishes it has been done and seen: the file built and opened, the commit pushed, the open item closed or handed to the candidate by name (`cases/a-task-reported-done-without-the-act-that-finishes-it.md`).

## Written answers beside the CV

An application form's questions are answered by the same four phases, with two things added. Where the employer asks that the candidate draft first, the candidate drafts first, and the agent's work begins from that draft (`cases/the-candidates-own-account-written-for-him-before-he-gave-it.md`). And an answer needs its angle chosen, by the candidate, before it is drafted. Where none is chosen the judges' ranking ends up choosing it, and then nobody decided what the answer argues (`cases/an-answer-drafted-with-no-angle-chosen.md`).

## Relationship to other methodologies

- **SIFT → HIRE**: a listing marked `respond` in SIFT becomes a HIRE run. SIFT's dossier on the listing is the first source for `hirer.md`.
- **HIRE → SIFT**: what the candidate says in I about scale, dates and what stays off the page belongs in the operator profile SIFT scores against, so the next run does not ask again.
