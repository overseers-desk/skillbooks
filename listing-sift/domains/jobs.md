# SIFT for job listings

What holds for every SIFT campaign whose listings are jobs. `../sift-methodology.md` holds what holds for every listing, and the campaign's configuration holds what one operator chose.

## Terms

- **Post.** The position a listing offers.
- **Employer.** The organisation the post is with. Where the employer publishes its own listing, it is the listing's publisher and its name is `source_name`. Where a recruiter or an agency publishes for an employer, the methodology's step on researching the source applies to that publisher, and what the listing says of the employer stays in the dossier's listing description.
- **Sector.** The industry the post belongs to.
- **Operator.** The person looking for a post.
- **Response.** A candidacy: a CV and the written answers that travel with it.

## What the campaign configuration sets

A job campaign's configuration holds these, beside what every configuration holds:

- the places of each kind of source the campaign searches, and what to search for there;
- the campaign's currency, and the rates for converting other currencies into it;
- the seniority ladder for the operator's occupation;
- the list of role families;
- the dimensions the campaign uses, in order, with the two pay thresholds, the operator's capacity, and any examples added to an anchor;
- the method that prepares the candidacy, where the campaign uses one.

## Sources

Sweep looks in these kinds of place:

- The employer's own careers page or applicant-tracking board. Sweep prefers it over a copy elsewhere.
- Job boards for one occupation or sector.
- General job boards.
- Job boards for one country or region.
- Alert emails a job board sends for a saved search.
- A listing passed on by a person, entered with `source` set to `referral`.

An agent with a skill installed for a job board uses it to search the board and to read a listing.

## Columns

A job campaign's registry carries these after the core columns, in this order. The campaign's own columns follow them.

| Field | Type | Written by | Purpose |
|---|---|---|---|
| work_mode | enum: remote/hybrid/onsite/unknown | Sweep | Where the work is done |
| seniority | enum | Sweep | Level of the post, on the configuration's ladder |
| comp_estimate | string | Sweep; Fit revises | Annual pay as the listing states it, in the campaign's currency. `45k-52k` is a stated range, `50k` a stated figure, `>60k` a stated floor, and `~50k` an estimate, made where the listing states no pay or states it by the hour or the day |
| role_family | enum | Sweep | The kind of work, from the configuration's list |
| one column for each dimension the campaign uses, in the configuration's order | number | Fit | The dimension's score, under the dimension's name |
| pct_amplifier | text | Fit | The amplifier tags that apply, comma-separated |
| approach_channel | enum: cold-apply/warm-intro/recruiter/network | Target | How the employer is to be reached: a direct application, an introduction by someone the operator knows, through a recruiter, or by building a relationship first (the `network-approach` disposition) |
| contact_notes | text | Target | Contacts the operator has named, referral paths, recruiters' names |

## Dimensions

The star rating of a job campaign is the sum of the dimensions the campaign uses, those below and any of its own, clamped as the methodology says. `influence_knowledge` is the base of the sum and the others adjust it, so a campaign uses it or defines another dimension on the same scale in its place.

### influence_knowledge (integer, 1–5)

What the post would teach the operator, and whom it would put the operator among. The questions below are weighed together into one score, at the anchor the post as a whole sits nearest:

- **Access.** Does the post work on systems, information or decisions that few people outside the employer see?
- **Peers.** Whom does the holder of the post deal with as equals: the employer's own staff, people in other organisations, or the people who regulate or fund the sector?
- **Scarcity afterwards.** Is what the post teaches still scarce and useful once the operator has left it?

| Score | Anchor |
|---|---|
| 1 | Ordinary work of the occupation. What the post teaches can be learnt in many places |
| 2 | Some depth. The post teaches one system or method of the employer's own, or works with one outside organisation |
| 3 | The post shows how its sector works behind what outsiders see, or works across several organisations. What it teaches carries to other employers |
| 4 | The post designs or runs something other organisations in the sector depend on, and deals directly with those who regulate or fund the sector. What it teaches is hard to learn elsewhere |
| 5 | The post makes its holder one of the few people who understand how a major part of the sector works |

### comp_modifier (−1 / 0 / +1)

Derived from `comp_estimate`: the midpoint of a range, otherwise the figure. A figure below the configuration's lower threshold scores −1, one above its upper threshold +1, and one between them 0. Where Fit's reading of the dossier gives a materially different figure from the one Sweep entered, Fit revises `comp_estimate` and notes the basis.

### stepping_stone (0 / +0.5 / +1)

What holding the post would do for the operator's next search. Two things can hold. The post gives the operator an experience or a credential that listings ask for and the operator profile lacks. The employer is one that people who hire will recognise without explanation.

| Score | Anchor |
|---|---|
| 0 | A sideways move: neither holds |
| +0.5 | One holds, or both |
| +1 | Both hold, and having held this post at this employer would open a kind of post the operator cannot get now |

### labour_fit (−1 / 0 / +1)

Whether the post's demands fit the time and attention the operator has for it. The configuration states how much the operator has, or says where the operator profile states it. A campaign whose operator has no limit on either leaves this dimension out.

| Score | Anchor |
|---|---|
| +1 | The post's demands fit within the operator's time and attention |
| 0 | They fit in part: some of the work asks for more than the operator has |
| −1 | The post asks for sustained time or attention the operator does not have |

## Target and the response

For a listing whose `decision` is `respond` or `network-approach`, Target records how the employer is to be reached (`approach_channel`) and the contacts the operator has named there (`contact_notes`).

Where the configuration names a method that prepares the candidacy, Target's part for a listing marked `respond` ends with the decision. Target does not choose what the candidacy opens on and argues, or what it emphasises. `../sift-campaign-directory.md` says how the campaign directory sits beside that method's files. When the candidacy is sent, whoever sends it records the sending in the listing's registry row (`date_responded`, `status`).

Where the configuration names none, the methodology's general rule applies: Target notes in `notes_target` what the operator's CV should emphasise for this listing.
