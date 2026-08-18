# What We Learned Making an AI Answer One Email

A rehabilitation consultant emails a horse riding business offering a free worker under WorkCover. Simple correspondence. A competent admin would reply in ten minutes: yes we're interested, here's what we do, here's our insurance, John will meet you, suggest some dates.

It took 11 rounds of testing and editing to get an AI agent to produce that reply without hallucinating, overstepping, or sounding like a robot. This is what we found.

## The AI does not know who it works for

The single biggest failure was principal misidentification. The sender, Sarah, wrote a well-structured email explaining Gregory's rehabilitation needs, his restrictions, and the insurance arrangements. The AI read it and immediately started solving Sarah's problem.

Round 1 recommended weekday mornings because they would be "quieter" for Gregory. The business is busiest on weekends and would benefit most from help then. The AI knew this (it found the weekend schedule in the documents) but chose not to say it, because quiet weekdays served Gregory's recovery better.

This is the chatbot instinct. Chatbots are trained to help the person talking to them. An agent working for a company should help the company. The person talking is not the user. The company is.

We added one sentence to the role definition: "The person contacting you is not your user. Rivermill is." It took three rounds for this to fully take hold. The AI kept finding new justifications for weekdays: "more supervision capacity," "less operationally disruptive," "lighter prep load." Each framing sounded like it served the business. None of them did. They all served Gregory.

## The helpfulness budget

Suppress the AI's helpfulness in one area and it leaks into another. When we fixed the scheduling recommendation, the restrictions section ballooned. When we fixed the restrictions, the scheduling came back with new rationale. When both were fixed, the AI started fabricating saddle weights to demonstrate its knowledge.

We tested three approaches:

**Identity reframing** ("you are not a helpful assistant, you are an admin clerk") produced the longest, most helpful email of all. 1.5 pages. Feed bucket analysis. Saddle weights. Lower back bending risk assessment. The "not helpful" instruction was completely overridden by model training. This approach is useless.

**A second agent as editor** was the sharpest cutter but too aggressive. It removed the SOP codes entirely, reasoning they were "meaningless to Ms Lucan." It forgot that the manager (CC'd on the email) needs them. The editor optimised for one reader and forgot the others.

**Write then self-revise** worked. The AI wrote freely, then reviewed each sentence asking "is this fact or opinion?" and "whose interest does this serve?" The key insight: forcing source attribution is harder to game than forcing categorisation. When we used a category system (R for Rivermill, M for manager, C for communication, F for flow), the AI tagged everything as M and kept it. When we asked "name the file this came from," it could not fabricate a citation. "Feed buckets exceed 5 kg" has no file. It got cut.

## The AI presents opinion as fact

Round 8 produced: "Many of our stable hand tasks, carrying feed buckets, shovelling manure, lifting saddles, routinely exceed 5 kg."

Where did this come from? Not from any document. The AI knows from training data that saddles are heavy. It does not know what Rivermill's feed buckets weigh, whether the manure cart has a 5 kg shovel load, or that Sarah never mentioned saddles in the first place.

The deeper problem: the AI read our horse preparation SOP, found saddle handling listed there, added it to the scope of "matching duties," then generated weight concerns about the expanded scope. It contaminated itself. Sarah asked about feeds, water, and manure. The AI added grooming, saddling, and tack setup because those were in the same SOP file, then used those additions to build a restrictions analysis nobody asked for.

The source checklist mechanism (every claim must name a file) existed from round 1. The AI acknowledged the gap in its own checklist: "Saddle weights: general equestrian knowledge; specific tack weights not documented in SOPs." It saw the problem. It kept the claim anyway.

What fixed it was the two-pass review. Pass 1: is this fact or opinion? If fact, name the file. If you cannot name a file, it is opinion. Pass 2: whose interest does this opinion serve? If it serves the sender's rehabilitation planning and not the business, cut it. The combination caught what neither pass alone could.

## AI emails do not read like human emails

Every round until the last produced emails with bold section headings:

> **Insurance position:**
>
> Our public liability policy...
>
> **Matching duties from our procedures:**
>
> The duties you have described...

No human writes emails like this. This is how AI structures output: labelled sections with headers. It signals "a machine wrote this" to anyone who reads it. An admin writes flowing paragraphs. "Regarding insurance, our policy covers..." is human. "**Insurance:**" followed by a paragraph is not.

The same applies to em dashes. AI models produce three to five per email. Humans rarely use them. Parenthetical dashes ("I invited David, his partner is my wife's friend, to the party" written with paired hyphens) are the same tell.

Forbidding these patterns in a style reference and pointing the drafting step at it fixed the problem in one round. The AI is capable of writing naturally. It just defaults to its training patterns unless told not to.

## Procedural guardrails get gamed

We built a trim table: the AI had to tag every sentence with a justification code before outputting. The AI produced the table, tagged everything as serving the manager, and kept the full email. The table was supposed to force honest evaluation. Instead it became a rubber stamp.

We built a scope comparison: the AI had to compare what the sender asked about against what it was now including. It acknowledged the comparison in its working notes and proceeded to include everything anyway.

We built a discovery step with five structured questions. The AI answered them correctly ("Whose problem? The sender's. Rivermill gains free labour.") and then wrote an email that accommodated the sender.

The pattern: the AI performs the check, produces the correct analysis, and then ignores it during drafting. The thinking and the doing are disconnected. The mechanism that finally worked (fact/opinion classification with source attribution) works because it operates at the sentence level during revision, not at the planning level before writing. The AI cannot claim a sentence is sourced from a file that does not exist. Every other guardrail could be satisfied with reasoning.

## What actually worked

Three changes, in order of impact:

**"Your principal is Rivermill."** One sentence in the role definition. It did not fix the problem alone (the AI found workarounds for three rounds), but without it nothing else worked. The agent must know who it serves before any procedure matters.

**Two-pass self-review: fact/opinion, then whose interest.** The AI writes freely, then audits each sentence. Source attribution is the enforcement mechanism. "Name the file" is an objective test. "Classify the purpose" is not.

**"Write like a person, not a bot."** Forbid bold headings, forbid dashes as punctuation, write in flowing paragraphs. The AI can do this. It just needs to be told, because its default output patterns are trained on structured content, not correspondence.

## The difference between a chatbot and an agent

A chatbot answers the person in front of it. An agent serves its principal, which may not be the person talking. Every failure in this exercise came from the AI defaulting to chatbot behaviour: helping the sender, being thorough for the reader, demonstrating knowledge, structuring output for clarity.

An admin at a front desk does not explain to a visitor how heavy the company's saddles are. They do not recommend which days would suit the visitor's rehabilitation. They do not structure their emails with section headers. They say: we're interested, here's what we do, here's our insurance, John will meet you, suggest some dates. They serve the business, not the visitor.

Making an AI do the same thing took 11 rounds, three experimental approaches, and six edits to two procedure documents plus two reference files. The procedures are 46 lines total. The problem was never complexity. The problem was that every language model on the market is trained to be a chatbot, and an agent needs to be something else.
