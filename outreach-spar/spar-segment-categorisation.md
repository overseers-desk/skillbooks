# SPAR Segment Categorisation

**Applies to:** campaign planners defining the segment structure for a SPAR outreach campaign

**Prerequisite reading:** `spar-methodology.md` (defines the SPAR phases and how segments fit into the overall flow)

## 1. What a segment is

A segment is one directory containing one roster, one segment file, one set of profiles, and one set of approach files. The progress script discovers segments by scanning for `roster.tsv` files. Each segment appears as one row in the progress report. A segment is the unit of pipeline management: it has its own S&P iterations, its own approach sequencing, and its own summary file.

The segment structure is a design decision made at campaign planning time. It can be revised during the campaign when evidence shows the initial structure is wrong — but revising it mid-campaign means moving files, merging rosters, and rewriting segment files, so the cost of getting it wrong is real.

## 2. The deciding question

The question is not "are these contacts similar?" but "does contacting them require materially different work?"

Two contacts are in the same segment when the segment file, the first ask, the conversion funnel, and the approach procedure apply to both without modification. They are in different segments when at least one of these differs enough that a single segment file would need conditional sections to accommodate both.

The threshold is practical, not taxonomic. A campaign does not need a segment for every noun that describes a contact type. It needs a segment for every distinct combination of pitch and procedure.

## 3. Indicators that two segments should merge

The following are signs that separate segments create overhead without adding targeting precision.

**Same event or transaction.** If both segments recruit participants for the same event — a market day, a conference, a community gathering — the contacts are operationally interchangeable. A nursery and a cheesemaker both need to hear the same venue description, the same visitor numbers, and the same stall logistics. The difference in what they sell is a per-contact detail, not a segment-level distinction.

**Nearly identical first ask.** Compare the "first ask" sections of both segment files. If they could be combined by parameterising one or two words (the product name, the market name), the segments are doing the same work twice. A segment file that reads "we've seen your [product] and think you'd be a good fit" is the same goal regardless of whether [product] is "sourdough" or "succulents."

**Same conversion funnel.** If both segments follow the same sequence — build roster, reach threshold, set dates, confirm, announce — they are tracking the same process in parallel. A single segment with a larger roster reaches the threshold faster.

**Small overlap in contacts, but large overlap in ask.** The duplicate count between two segments may be low (one or two shared contacts), yet the structural redundancy may be high. The number of shared contacts is a weak signal. The similarity of the outreach process is the strong signal.

## 4. Indicators that two segments should remain separate

The following are signs that merging would harm targeting precision or operational clarity.

**Materially different pitch.** If the value proposition changes depending on which segment the contact belongs to, merging forces the approach writer to maintain two mental models within one segment file. An operator serving domestic coach tourists needs to hear about convenient hinterland stops and group catering. An operator serving inbound international visitors needs to hear about cultural authenticity and trade distribution. These are different arguments for different audiences, not parametric variations of one argument.

**Different conversion timeline or priority.** If one segment is Tier 1 with a 6-18 month sales cycle involving trade shows and offshore distribution, and the other is Tier 2 with a simple trial-period model, merging flattens the priority distinction. The high-priority cohort becomes a subsection of a larger segment rather than a standalone pipeline with its own sequencing.

**Different contact profiles.** If the two segments' contacts operate in different industries — even if the campaign's label for them sounds similar — they require different search vocabulary, different profiling sources, and different approach angles. The S phase for one segment would not find the other segment's contacts, and the P phase would evaluate them against different criteria.

**Different collateral or procedure.** If one segment requires a trade product sheet for offshore distribution while the other requires a simple experience description with photos, the approach procedure diverges. A merged segment file would need conditional logic: "if the contact is type X, do this; if type Y, do that." Conditional segment files are a sign that the merge is wrong.

**Asymmetric pipeline stage.** If one segment is at S&P3.AR1 (approaches being sent) while the other is at S&P1 (still discovering contacts), merging mid-campaign creates confusion about what stage the combined segment is in. The progress report would show a blended number that misrepresents both halves.

## 5. Sub-segments within a segment

A segment need not have a single purpose. It is acceptable — and sometimes preferable — for a segment to contain sub-segments with different immediate asks, provided the contacts share enough operational context that a single segment file can accommodate them without becoming conditional.

The mechanism is a named section in the segment file. The main body defines the default approach for the majority of contacts. A clearly labelled section defines the variant approach for the sub-segment. The roster does not need a sub-segment column; the approach writer reads the segment file and applies the appropriate section based on what the profile says about the contact.

This is appropriate when:

- The sub-segment is small (fewer than ~10 contacts) and does not justify its own directory, roster, and segment file.
- The sub-segment's contacts were discovered during the same S phase, using the same search vocabulary, and appear in the same industry directories.
- The variant ask is a narrower or more exploratory version of the main ask, not a fundamentally different proposition.

This is not appropriate when:

- The sub-segment is large enough that its contacts would dominate the segment's metrics, obscuring the main sub-segment's progress.
- The sub-segment's approach procedure differs in channel (e.g., LinkedIn-first vs email-first) or in collateral requirements.
- The sub-segment's contacts would never be discovered by the main segment's search queries.

## 6. Handling shared contacts across segments

When the same person appears in two segments that remain separate, the risk is that they receive two emails from the same campaign — one from each segment — which looks disorganised.

The solution is not to merge the segments but to coordinate the approaches. Three mechanisms, in order of preference:

**Single combined approach.** Write one approach file that addresses both angles. Place it in whichever segment the contact is more strategically valuable to. In the other segment's roster, set `a_note` to reference the combined file's location. The progress script will show the contact as "no approach file" in the second segment; this is acceptable and expected.

**Sequenced approaches.** If both angles are genuinely worth separate messages (because they address different divisions or roles within the contact's organisation), send them in sequence with enough time between them that the second message can reference the first. The second message should acknowledge the prior contact: "I wrote to you last month about X; I'm now reaching out about Y."

**Roster cross-reference.** At minimum, add a note in both roster rows indicating the cross-segment appearance. This ensures that anyone reviewing one segment's roster is aware of the other segment's claim on the same contact.

The duplicate-contacts section of the progress script (`update-campaign-progress.py`) flags cross-segment duplicates by name and by email. These flags are not errors to be fixed by merging; they are coordination points to be resolved by one of the three mechanisms above.

## 7. When to revisit the segment structure

Segment structure should be revisited at two points:

**After S&P3, before AR begins.** The roster is complete. The progress report shows the actual contact counts and overlap. If two segments have high structural redundancy (same ask, same funnel) with only cosmetic differences, this is the cheapest time to merge — no approaches have been sent, so no coordination is needed.

**After AR1, during R.** The first band of responses may reveal that the campaign's assumed segmentation does not match how contacts see themselves. A contact classified as "inbound tour operator" may respond as a domestic operator who happens to also handle inbound groups. If this pattern recurs across multiple contacts, the segment split may not reflect reality.

Do not revisit segment structure mid-S&P unless discovery reveals that the two segments' search vocabularies are identical (the same queries find the same people). In that case, the segments are empirically the same and should be merged before P begins.
