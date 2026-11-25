# HIRE — Writing a Candidacy

## What HIRE is

HIRE is a four-phase methodology by which an AI agent writes the document that puts one candidate forward for one post: a CV, and the written answers that travel with it. The name is an acronym:

- **H** — Hirer. Establish who reads the document, how it reaches them, and what they lack that this candidate brings.
- **I** — Interview. Draw on the candidate's standing account of the work and the facts only the candidate holds, taken once and kept, and decide for this reader what the candidate has not said.
- **R** — Reframe. Select from the record and write each fact as the answer to a question this reader has, at the candidate's level and in the candidate's voice.
- **E** — Examine. Put the draft before readers who are not the writer, and repair it, until the stop rule is met.

HIRE starts from a post already judged worth answering.

## The problem HIRE solves

An agent asked for a CV has the candidate's record in front of it and a strong habit of what a CV looks like. Left to both, it produces a document that is correct, complete and addressed to nobody. It arranges what it knows; a candidate who speaks to a reader arranges what the reader lacks. The agent cannot see the difference from the inside, because it checks its sentences against the thought it already holds and its drafts against its other drafts.

The second problem is recurrence. A candidate corrects a line; the agent mends that line and writes the same fault into the next. The corrections that follow are the same from one application to the next: detail below the level of the post, a fact told as the story of finding it out, an open question closed, a sentence carried over from a document written for someone else.

HIRE answers the first by fixing the reader and taking the candidate's own telling before any sentence is written. It answers the second with the cases in `cases/`: each is a fault that happened, the class it belongs to, and a way to re-run it. Every rule below names the cases it came from. A rule that reads as arbitrary has a case that explains it.

## What a run produces

A candidate applies to a hundred posts or more in one search, and does not sit with each. So two things live above the single application, in the candidate's own repository:

- **The candidate file**: the candidate's own account of the work and the answers only the candidate holds, taken once and added to whenever the candidate corrects something. Every application reads it. It also holds the search's defaults: what an application does where the record is silent, such as which of several figures stands or whether an unmentioned private matter goes on the page. These are the candidate's choices, so they live here and not in this method.
- **The assumption register**: one table for the whole search, a row for each assumption an agent made in any application. Most rows are about the hirer ("the person who fills this post wants someone who has led at this size"); the rest are about the candidate, where the candidate file was silent. Each row gives the application, the assumption, a confidence score, what it rests on, and what in the document depends on it. The candidate reads down the table across applications and marks each row agreed or not. A row marked wrong corrects the candidate file, or becomes a standing assumption about that kind of hirer, so the same one is not made wrongly twice.

Then one working folder per application, holding:

| File | Written in | Holds |
|---|---|---|
| `brief.md` | H and I | The post, the route, the readers, what they lack, and the four sentences Examine's readers are given; what was taken from the candidate file for this application, each item with its source; and each decision made where the record was silent |
| `approaches/` | R | The competing openings and outlines, and how one was chosen |
| `selection.md` | R | Each fact considered: the reader's question it answers, what it says of the candidate beyond itself, and whether it is kept, recast or left out |
| the document | R | Named by the date and time it was made; earlier versions move to `superseded/` |
| `examine.md` | E | Each check run, what it raised, what was done, and what the candidate said on reading |

These files are HIRE's own, and HIRE writes nowhere else, with one exception named below. The candidate file may be one the candidate keeps for other uses as well: HIRE reads and adds to the parts listed under I, and leaves the rest.

Where the candidate keeps a list of the postings under consideration, with research on each, an application works with it in three ways. The research on file about the post (the advertisement as archived, background on the employer) is the first source for `brief.md`; a score or an opinion found in it is somebody's inference, and is marked as that. `brief.md` and the application's rows in the register name the posting by the list's own identifier. When the document is sent, whoever sends it enters that in the list, which is the exception.

A file's time is read from the clock when it is written (`cases/a-task-reported-done-without-the-act-that-finishes-it.md`).

## H — Hirer

A document is not begun until `brief.md` exists for it. A repair to a document already under way is made with `brief.md` open beside it. Both efforts this method came from began drafting first and learnt the real reader days later (`cases/drafting-before-the-reader-and-the-route-were-known.md`).

Establish, and mark each line with where it came from (the advertisement, the candidate, another named source, or your own inference):

- **The post behind the advertisement.** An advertisement may be a template for a different level, or written before the post was defined. Its level, its reporting line and the size of what it leads come from the candidate file and from anyone who passed the advertisement on; what neither gives is an assumption, scored and registered. Write for the post, and treat the advertisement's wording as a signal of the employer's vocabulary.
- **The route.** Who reads first, who decides, in what language each reads, and in what form the document reaches each. A PDF forwarded inside an organisation travels alone; a form's other fields may not go with it. What a later reader will not see has to be in the document itself.
- **What these readers have plenty of, and what they lack.** Picture the other applicants. A hospital is not short of clinicians, and a law firm is not short of lawyers. The document's argument is what this candidate brings that the others do not.
- **The readers' own subject and terms.** Read what the employer has published on the matter the candidate will speak of. An expert reader expects the field's terms (`cases/terms-of-art-paraphrased-for-an-expert-reader.md`).
- **The employer's rules for applicants**, such as who may draft what. They are read here, since they decide the order of work in the phases that follow (`cases/the-candidates-own-account-written-for-them-before-they-gave-it.md`).

An inference in `brief.md` is an assumption, and goes into the register with a confidence score: what this hirer wants, who reads first, what level the post is. Low-confidence rows that much of the document depends on are the ones to put at the top for the candidate. A judge's brief and a reader line carry what the advertisement and the candidate said; an assumption put there comes back as the judge's finding (`cases/judges-briefed-with-the-writers-own-inference.md`).

H closes with four sentences, which Examine hands to its readers:

- the **reader line**: who reads, and what they have read before this;
- **reading-for**: the decision the reader is making, and nothing about the field;
- **taken-for**: whom the candidate is to be taken for, with no numbers in it;
- **must-not-conclude**: the conclusions the candidate does not want drawn. This one is filled in I, from the candidate's own fears, since a conclusion the writer supposes produces rows about the writer's worry and none about the candidate's.

## I — Interview

**Read the record first, whole.** Everything in the candidate's own words: recorded conversations, essays, earlier accounts of the same work, notes. Read them through; a keyword search finds what was already expected. A question whose answer the record holds is not put to the candidate (`cases/questions-asked-whose-answers-the-record-held.md`), and a claim that the record lacks something is made after a search for it (`cases/guesses-written-in-as-the-candidates-facts.md`).

**The candidate file is filled in once.** Before a search begins, or the first time HIRE runs for a candidate, ask in one sitting what only the candidate holds, and keep the answers in the candidate file:

- The candidate's own account of the work, spoken if possible and kept as given, told to each kind of reader the search will meet (one who hires a leader, one who hires a specialist, and so on). Put it as a question: what does this kind of reader want from someone like you?
- What the candidate wants to be taken for, and what the candidate fears a reader will conclude.
- What stays off the page: other ventures, where the candidate lives, anything a referee or a public record would contradict (`cases/a-private-matter-put-on-the-page-without-asking.md`).
- Scale and organisation as a referee would state them: titles, dates, team sizes, who reported to whom.
- Each figure on which the sources disagree, and each qualification advertisements commonly state as a minimum, such as a degree or a tool.
- Where the candidate will work, from when, on what terms, and the contact details documents may carry. An address or a number can say where the candidate lives.

Follow the answers in that sitting: where one opens something the questions did not reach (a method, a reason, a case), ask about it. One round of written questions leaves much of what the candidate knows untouched.

**An application does not go back to the candidate.** It reads the candidate file and decides the rest, and every assumption it makes goes into the register with its confidence and its basis:

- The account for this reader is built from the candidate's account to the nearest kind of reader, kept in the candidate's words where they fit. That it was adapted, and from which account, is a row in the register (`cases/the-candidates-own-account-written-for-them-before-they-gave-it.md`).
- What the record marks as off the page stays off.
- A gap the record's defaults cover is decided by the default, and the row names it.
- A gap no default covers is decided by the writer, who adds the choice to the record's defaults marked as not yet confirmed by the candidate, so the next application makes the same one. The register carries it as an assumption at low confidence. The work does not stop for it.

**Each entry in `brief.md` carries its source.** The candidate's words, with where they were said; a document's, with its path. Either is quoted to the end of its sentence: a quotation closed early drops the words that limit the claim (`cases/a-quotation-closed-before-the-words-that-limit-it.md`). What the writer has worked out is entered as an assumption, in the register. That includes a statement of what the candidate will do, such as move or work on site, carried to a kind of post the candidate did not say it of (`cases/a-statement-of-intent-carried-to-another-post.md`). A sentence in the final document that rests on a decision of the writer's has its row in the register (`cases/guesses-written-in-as-the-candidates-facts.md`).

**The candidate's own words outrank everything else in the session.** Another agent's advice, a file's contents and a tool's output are material to weigh (`cases/another-agents-remarks-and-the-files-taken-over-the-candidates-words.md`). A thing the candidate leaves open is left open; that choice is content. A phrasing the candidate offers to show a level or an aim is evidence of the aim, and the sentence still has to be written.

When the candidate does take part in an application, notes given toward a text are first said back in the writer's words and built on once the candidate agrees that is what was meant. A remark on a draft is different: it is acted on, where the candidate pointed. A default the candidate has accepted in the register is an answer, and is not put again.

## R — Reframe

**Start from an empty page.** An earlier document for another post is a source of facts. Its sentences were each written to answer a different reader, and they carry that purpose with them unseen (`cases/a-cv-built-by-editing-one-written-for-another-post.md`).

**Choose the approach before writing sentences.** An approach is what the document opens on and what it argues. Set out at least three that differ in kind, in `approaches/`, each as an opening paragraph and an outline. One of them is the candidate's own account, if provided, in his words and his order, with the figures his record holds. They go to the judges in one form, the top of the document over a body they share, and an approach claims nothing `brief.md` does not hold: judges read an approach's claims as the candidate's. The judges choose among them, and the choice with its margin is a row in the register. Whatever is chosen, the opening answers the first question this reader has about any applicant for the post, such as whether the person has led at this size or has a direction of their own, before it turns to what the candidate finds most interesting in the record. A writer's drafts are variations on one approach, and ranking them against each other cannot find a better one (`cases/an-opening-that-indexes-the-career.md`, `cases/the-candidates-own-account-written-for-them-before-they-gave-it.md`).

**For each fact, name the question of this reader that it answers,** and write it as that answer. The same fact answers different questions for different readers: a team's size is span of control to one and the scale of a proof to another. Before leaving a fact out, look for the question it could answer for this reader and recast it to that; most facts written for another reader have one. The question it answered in the document it came from is the old reader's and does not count. A fact that still answers none stays out, however true and however hard-won. `selection.md` records each decision, so the candidate can see what was left out and why (`cases/a-true-detail-kept-because-it-was-known.md`).

**Write at the level of the post and the person.**

- A document states what was established, at what scale, and what the candidate is working on. How a system is wired, which tools built it, counts of its parts and incidents told with their times and places belong to the conversation the document is meant to win (`cases/detail-below-the-level-of-the-post.md`).
- Where H found the post sits above its advertisement, the advertisement describes the work of the people the candidate would lead. The document shows the candidate leading such work and deciding its direction. An opening that walks through the advertisement's duties as the candidate's own pitches the candidate a level low (`cases/drafting-before-the-reader-and-the-route-were-known.md`).
- Each thing the advertisement asks for is met on the page by a fact with its result. Where the candidate has many such facts, the two or three nearest this reader's own work are set out with what came of them; a count of them ("over a hundred clients") is not evidence of any one.
- A claim the document rests on carries its evidence beside it: a count, a measured result, or one instance. A direction with no evidence reads as a proposal from someone who has not done the work.
- One instance may stand behind a claim that would otherwise sound empty. A category is shown by naming a few of its members as examples.
- A whole passage should sit at one grain. Where the opening speaks in theses, an entry below it that drops to anecdote reads as part of a different document.

**Write in the voice of someone who knows.**

- State what is the case. "The evidence is a catalogue of N failures" is a statement; "I catalogued N failures" is a report of homework, and "I found that" tells the reader the story of finding out (`cases/a-statement-of-fact-told-as-finding-out.md`).
- Keep open what the candidate left open. "Some of the causes, for example" where the writer was about to write "the causes are three". "Has worked best so far" where the writer was about to name the best (`cases/an-open-question-written-as-settled.md`).
- The subject of a sentence is what the candidate can do, and its verb says who directs whom. A figure that praises the venue, the team or the tool gives the achievement away (`cases/the-sentences-subject-gives-the-achievement-away.md`).
- A quality is shown by a fact. A label for it ("strong leader") is the thing every applicant writes (`cases/a-quality-claimed-by-label.md`).
- A defence against a charge the reader has not made plants the charge (`cases/a-denial-nobody-asked-for.md`).

**Mind what the reader will conclude beyond what is said.** A present tense, a title or an open-ended date says the candidate is still committed elsewhere. A place says where the candidate lives. A size, a duration, a rate or a link says how big, how slow or how little used; ask what each says of the candidate before it goes in. Check each against must-not-conclude (`cases/a-tense-or-a-date-that-says-the-candidate-is-not-free.md`, `cases/a-true-detail-kept-because-it-was-known.md`).

**Give the reader a thing before referring to it,** and make the opening tell the same story as the entries below it (`cases/a-thing-named-before-the-reader-has-it.md`).

**The candidate's wording changes only for a reason the candidate can see.** This is about the candidate's own sentences. Putting the field's term where the writer had a plain word, and tidying spelling and grammar, are ordinary editing and are listed all the same. Every such change is a row in the register with its reason, so it can be taken back (`cases/the-candidates-words-swapped-or-removed.md`).

**Edit by rewriting from the thought.** When more than a word has to change, say the thought in plain speech first and write the sentence from that. A sentence patched inside its old frame keeps the frame and loses the parts that made it mean something, and the writer, who holds the thought, reads the stump as whole (`cases/a-sentence-patched-until-it-meant-nothing.md`).

**After any edit, read the whole document again.** An edit is made where the candidate pointed, and checked against everything else on the page: what it now repeats, what it now contradicts (`cases/a-repair-checked-only-against-the-remark-it-answered.md`).

**Length follows content.** A word allowance is a ceiling, and the text ends at the last sentence the reader would miss (`cases/length-set-by-the-allowance.md`).

## E — Examine

Examine runs cheap readers before dear ones, and the candidate last. Every check and what came of it goes into `examine.md`, a one-sentence repair included, with its evidence saved in the folder: what each reader was given and answered, each script with its output.

### 1. Sentence readers

Run prose-stethoscope on the draft, on a copy in which any template markup is replaced by the words the reader will see. For a CV, name every module the skill lists for one and give it the four sentences from `brief.md`. Add this folder's two modules by path:

- `modules/restate.md` asks whether the reader can say in their own words what a sentence asserts. It is the check for a patched sentence.
- `modules/grain.md` asks whether a sentence sits at a much finer level of detail than the document around it.

Two runs; three where a decision rests on one row or the two runs split. Then read the rows as a reader's reports:

- A row on a line that is the candidate's own wording leaves the line standing, and is entered in the register for the candidate.
- A row from `level` or `work` invites a cut. Act on one only when most runs agree, and treat cutting as the last answer to it: a measured result or the sign of the candidate's own building may be what the reader came for. A fact that stands in a document the candidate approved needs more than these readers, who never see the advertisement: it stays, its row goes to the register, and it comes out only where judges prefer the version without it (`cases/a-line-cut-on-one-readers-flag.md`).
- `total` has grown quiet; read its 3s.
- Rows that only report the form of a CV, such as the entries repeating the summary, are left.

What these readers cannot tell you is whether the document speaks to anyone. A draft can clear every row and be the wrong document (`cases/an-opening-that-indexes-the-career.md`).

### 2. The common-sense reading

A fresh agent gets the advertisement and the document, and nothing else. It is asked to say who this applicant is and what the post is, then to go through the document paragraph by paragraph, asked both ways by name: for this post and this person, which lines are finer than a reader would expect here, and which claims are too general to hold? It reports both, and what is right as it stands. Asked only where the text falls short, a reader lists detail it wants and never a line too fine (`cases/detail-below-the-level-of-the-post.md`). It also says in one sentence what the applicant works on and what it would ask them about; a reader who cannot has been given an index of a career (`cases/an-opening-that-indexes-the-career.md`). This is the check that finds grain and inherited sentences, and it costs one call.

### 3. Voice

On a copy: speak-like with the identity `human`, for machine cadence, capping lines and turned-round sentences (`cases/machine-cadence-in-a-personal-document.md`); this-guy-aint with the reader's own trade as the identity, for a plain word where the trade has its term.

### 4. Sources

Every figure and every claim of fact in the document is traced to an entry in `brief.md`, in a trace written down with the document's words and the source's words side by side in each row. Without the source's words in the row, the writer reads its own words as the source's, and a step past the source passes (`cases/a-sources-check-made-without-the-sources-words.md`). A quoted claim is read against its source past the quotation marks, to the end of the sentence. One that traces to the writer's inference is taken out. One that goes a step past its source is brought back to what the source says, and the stronger claim becomes a question in the register: a row there records an assumption and does not put it on the page. Whether a low-confidence assumption about the candidate may go on the page is one of the candidate file's defaults; one about the hirer may shape the page, since that is what it is for. A superlative needs a source a reader could open, and a title or a date is given as the referee would give it. Check that the document carries the candidate's contact details from the candidate file; a document without them is not complete, and its row says so. Then read the finished page against each ruling and default in the candidate file, one at a time. A ruling made after a document the candidate approved outranks that document, in form as in fact.

Before the last pass of checks 1 to 4, compare the document by script with every document the candidate has sent and with the newest document of every other application in the search. A clause they share, or a sentence that differs by a word or two, is said again from the fact, unless it is a named source's own wording or wording the candidate file says stands. Writers working apart from one record reach the same sentences, and one recruiter may read two of the documents. What is re-said is new wording, and the pass that follows reads it. Run the comparison again once the other applications have stopped changing (`cases/sentences-shared-between-documents-of-one-search.md`).

A version in another language is examined in that language, by readers of it. A translation of an examined text has not itself been examined.

### 5. Judges

Judges are for choosing between versions. Each is a fresh agent that holds only its brief. When you use judges, have them compare directions, not single words. A sentence that reads better usually points to a change that belongs in several places, so test that set of changes together, all going the same way. Make the test as big as what the candidate, or the framing, is actually about: no smaller, no bigger. If the set is large, test half of it first, to see whether the direction helps. Every verdict is a forced choice between two versions; a score given to one text alone moves from run to run and settles nothing.

- One model, two wordings of the judges' brief, both orders: four judges. Add judges only when the two orders disagree, as further wordings run before anything is concluded; a round that follows the reading order shows no preference (`cases/more-judges-than-the-last-rounds-variation-called-for.md`, `cases/judges-whose-verdict-followed-the-model-or-the-order.md`).
- The same model judges every comparison in a search, and `examine.md` names it. Two models can reverse each other on the same pair, so their verdicts are not set side by side, and three models agreeing is still one opinion.
- A judge's brief holds the advertisement and what `brief.md` marks as coming from the candidate or a named source. A judge told what the reader values will value it (`cases/judges-briefed-with-the-writers-own-inference.md`).
- A judge's brief tells the judge not to look the candidate up.
- At least one version in any comparison of approaches was not written by this session: the candidate's own telling, or a real document of the same kind. Once that version has met each of the writer's approaches, the writer's approaches may meet each other.
- A judge made to name one thing to fix will name one whether or not anything needs fixing. Such an answer is a prompt to look, and what it asks for is weighed against the level of the document before anything is added.
- Judges do not hear dryness, and they prefer the advertisement's own words and the cadence of machine-written prose.

### 6. The candidate reviews

The candidate's review is of the register, across applications, and of whichever documents the candidate chooses to open. Each correction is recorded in the candidate's words and carried into the candidate file. Each objection to a document is set against whether any check had raised it; one that no check raised is a case for `cases/`.

### When a check's tool is missing

Where a skill named above is not installed, put the check's question to a fresh agent that holds only the document and the reader line, and record in `examine.md` that the check ran in that form. A check that could not be run at all is named when the work stops.

### The stop rule

Stop when a full pass of checks 1 to 4 leads to no change, and no version on file is preferred by the judges to the current one. The first full draft is one of those versions. Where the judges prefer an earlier version, what they name is put back into the current one; the earlier version does not replace it, since it lacks every repair made since. Whatever is done last, the page that is sent is the one the sources trace and the whole reading were made on. Then say plainly what remains: the rows left standing and why, the decisions in the register that most deserve the candidate's eye, and the claims resting on them. A document that has stopped is not thereby right; it is one the available readers can no longer improve.

A task is done when the act that finishes it has been done and seen: the file built and opened, the commit pushed, the open item closed or handed to the candidate by name (`cases/a-task-reported-done-without-the-act-that-finishes-it.md`).

## Written answers beside the CV

An application form's questions are answered by the same four phases, with two things added. Where the employer asks that the candidate draft first, the agent's work begins from what the candidate has written in the candidate file for that kind of question, and the register says so; where there is nothing, the application's row is marked at the top of the register as one the employer asked the candidate to draft (`cases/the-candidates-own-account-written-for-them-before-they-gave-it.md`). And an answer needs its angle chosen before it is drafted: from the candidate file where the candidate has given one for that kind of question, otherwise as a registered assumption. Where none is chosen the judges' ranking ends up choosing it, and then nobody decided what the answer argues (`cases/an-answer-drafted-with-no-angle-chosen.md`).
