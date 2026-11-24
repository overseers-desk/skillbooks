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
- the campaign's dimensions, in the order of their registry columns;
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
| one column for each of the campaign's dimensions, in the configuration's order | number | Fit | The dimension's score, under the dimension's name |
| pct_amplifier | text | Fit | The amplifier tags that apply, comma-separated |
| approach_channel | enum: cold-apply/warm-intro/recruiter/network | Target | How the employer is to be reached: a direct application, an introduction by someone the operator knows, through a recruiter, or by building a relationship first (the `network-approach` disposition) |
| contact_notes | text | Target | Contacts the operator has named, referral paths, recruiters' names |

## Dimensions

A job campaign defines what it weighs in its own configuration: each dimension with its name, its scale and what each score means, and which of them is the base of the sum. The operator says what matters and how much. As examples, job seekers weigh the pay against what they need, what a post would teach, what it would lead to, how far away it is, and whether its demands fit the time they have.

## Target and the response

For a listing whose `decision` is `respond` or `network-approach`, Target records how the employer is to be reached (`approach_channel`) and the contacts the operator has named there (`contact_notes`).

Where the configuration names a method that prepares the candidacy, Target's part for a listing marked `respond` ends with the decision. Target does not choose what the candidacy opens on and argues, or what it emphasises. `../sift-campaign-directory.md` says how the campaign directory sits beside that method's files. When the candidacy is sent, whoever sends it records the sending in the listing's registry row (`date_responded`, `status`).

Where the configuration names none, the methodology's general rule applies: Target notes in `notes_target` what the operator's CV should emphasise for this listing.
