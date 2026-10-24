#!/usr/bin/env python3
"""Count what a card set must carry before it reaches the owner, and refuse what falls short.

Usage: card-check.py <run-dir>
Reads every card under <run-dir>/3-decisions/ written on forms/card.md.
Refuses: fewer than two options carrying a figure; a recommendation naming no option or stating its
margin in a unit other than the runner-up's, or not the difference of the two figures unless the line states its derivation, or stated against an option weaker than the strongest other; a withheld recommendation that does not name
two options, the counts it stands at and the observation that would carry either; a recommending line that does not say what it rests on; a card with no What the counts say sentence, or one over thirty words; a held value (the Held stamp, or without one a Priors line citing a file) with no third derivation recorded (a backticked third-derivation file on the Third derivation line that exists); a card with no Written date; a card carrying corrections that no game brief under <run-dir>/briefs/ cites as RULED.
Reports: figured options per card; recommendations that match a held value, leave one, or are withheld, as counts and no more; mismatched margin units; legs marked differs; a RULED mark in a brief that carries no date. Each card's line ends with the date it was written, the date it was ruled, and the date a game brief gives its ruling, which the review compares.
"""
import re, sys
from pathlib import Path

NUM = re.compile(r"\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?")


def num(tok):
    return float(tok.replace(",", ""))
STOP = {"the", "and", "with", "from", "that", "this", "over", "into", "than", "each", "about"}
MONTHS = {m: i for i, m in enumerate("january february march april may june july august september october november december".split(), 1)}


def date_of(text):
    """The latest date a line states, as YYYY-MM-DD; runs write 2026-09-27 or 27 September 2026."""
    found = [f"{y}-{m}-{d}" for y, m, d in re.findall(r"\b(\d{4})-(\d{2})-(\d{2})\b", text)]
    found += [f"{y}-{MONTHS[m.lower()]:02d}-{int(d):02d}" for d, m, y in re.findall(r"\b(\d{1,2}) (" + "|".join(MONTHS) + r") (\d{4})\b", text, re.I)]
    return max(found, default="")


def card_key(cid):
    """Card 01 and Card 1 are one card."""
    return (cid.lstrip("0") or "0") if cid.isdigit() else cid.lower()


def game_marks(run, keys):
    """Per card, the dates the game's briefs give its ruling on their RULED lines; a line with no date gives "". A word after RULED that names no card is prose."""
    marks = {}
    for brief in sorted((run / "briefs").glob("**/*.md")):
        for line in brief.read_text(errors="replace").splitlines():
            for m in re.finditer(r"\bRULED\b\W{0,3}(?:Card\s+)?([A-Za-z0-9]+)", line):
                if card_key(m.group(1)) not in keys:
                    continue
                marks.setdefault(card_key(m.group(1)), []).append(date_of(line))
                if not date_of(line):
                    print(f"NOTE {brief.relative_to(run)}: RULED card {m.group(1)} carries no date, so the review cannot tell whether the game played on that card's current ruling")
    return marks


def unit(figure):
    """The unit a figure is stated in: % where present, else its last word without digits."""
    if "%" in figure:
        return "%"
    tokens = [t for t in NUM.sub(" ", figure).split() if t not in ("of",)]
    u = tokens[-1].strip(" ,;") if tokens else ""
    return u[:-1] if len(u) > 3 and u.endswith("s") else u  # "unit" and "units" are one unit


def parse(text):
    card = {"options": []}
    m = re.search(r"^## Card\s+(\S+)", text, re.M)
    card["id"] = m.group(1).rstrip("·").strip() if m else "?"
    in_table = in_corrections = False
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("**Options**"):
            in_table = True
            continue
        if in_table and s.startswith("|"):
            cells = [c.strip() for c in s.strip("|").split("|")]
            if cells[0] in ("option", "---") or set(cells[0]) <= set("-: "):
                continue
            if len(cells) >= 2 and not cells[0].startswith("<"):
                card["options"].append({"name": cells[0], "figure": cells[1]})
            continue
        if in_table and s and not s.startswith("|"):
            in_table = False
        # corrections are often a list under the label; they run to the next field or heading
        if in_corrections and s and not re.match(r"\*\*[A-Za-z ]+:\*\*|#", s):
            card["Corrections"] = (card["Corrections"] + " " + s).strip()
            continue
        in_corrections = in_corrections and not re.match(r"\*\*[A-Za-z ]+:\*\*|#", s)
        for key in ("Written", "Recommended", "What the counts say", "Held", "Priors", "Measured in", "Ruled", "Third derivation", "Corrections"):
            if s.startswith(f"**{key}:**"):
                card[key] = s.split("**", 2)[2].strip()
                in_corrections = key == "Corrections"
    return card


def prior_match(recommended, priors, options):
    """Inside the prior's stated range, or the prior's own word; a word every option shares is a unit, not a prior."""
    if not priors or priors.startswith("<"):
        return False
    # a figure written as a word (one, two, twelve) is a figure to the range rule
    WORDS = {w: str(i) for i, w in enumerate("zero one two three four five six seven eight nine ten eleven twelve".split())}
    words_to_digits = lambda t: re.sub(r"\b(" + "|".join(WORDS) + r")\b", lambda m: WORDS[m.group(1).lower()], t, flags=re.I)
    recommended, priors = words_to_digits(recommended), words_to_digits(priors)
    rec_nums = [num(x) for x in NUM.findall(recommended)]
    # a cited file's date or name is not a prior's value: strip dates and backticked paths before reading numbers
    priors = re.sub(r"`[^`]*`|\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2} (?:January|February|March|April|May|June|July|August|September|October|November|December) \d{4}\b|\b(?:19|20)\d{2}\b", " ", priors)
    for a, b in re.findall(r"(\d+(?:\.\d+)?)\s*(?:–|-|to|or)\s*(\d+(?:\.\d+)?)", priors):
        lo, hi = sorted((num(a), num(b)))
        if any(lo <= r <= hi for r in rec_nums):
            return True
    if any(num(p) in rec_nums for p in NUM.findall(priors)):
        return True
    # whole words only, a word inside a longer word is not the prior's; a plural is the same word
    stem = lambda w: w[:-1] if len(w) > 4 and w.endswith("s") and not w.endswith("ss") else w
    stems = lambda t, n=4: {stem(w) for w in re.findall(r"[a-z]{%d,}" % n, t.lower())}
    named = [stems(o["name"]) for o in options]
    shared = {w for w in set().union(*named) if sum(w in n for n in named) >= 2}
    return bool(stems(priors) - {stem(w) for w in STOP} - shared & stems(recommended, 1))


def main():
    run = Path(sys.argv[1]).resolve()
    cards = [parse(p.read_text(errors="replace")) for p in sorted((run / "3-decisions").glob("**/*.md"))
             if p.name != "review.md" and re.search(r"^## Card\s", p.read_text(errors="replace"), re.M)
             and not re.search(r"^## Third derivation", p.read_text(errors="replace"), re.M)]
    refusals, matches, leaves, withheld, held, returned, mismatched, differs = [], 0, 0, 0, 0, 0, 0, 0
    if not cards:
        print("REFUSED no card on forms/card.md found under 3-decisions/ (a `## Card N` heading per card)")
        sys.exit(1)
    marks = game_marks(run, {card_key(c["id"]) for c in cards})
    for c in cards:
        figured = [o for o in c["options"] if NUM.search(o["figure"])]
        if len(figured) < 2:
            refusals.append(f"card {c['id']}: {len(figured)} figured option(s); back to Survey as a named gap")
        rec = c.get("Recommended", "")
        name = rec.split(";")[0].strip()
        chosen = next((o for o in c["options"] if o["name"] == name), None)
        is_withheld = name.lower() == "withheld"
        if is_withheld:
            # no option is carried: the line names the two readings and what would carry either
            named = [o for o in c["options"] if o["name"] in rec]
            standing = re.search(r"standing at:\s*(.+?)(?=;\s*carried by:|$)", rec, re.I)
            if standing and len(standing.group(1).split()) > 20:
                refusals.append(f"card {c['id']}: the standing-at clause runs to {len(standing.group(1).split())} words; the form asks for twenty or fewer, the rest belongs on the Measured in line")
            if len(named) < 2 or not standing or not re.search(r"carried by:\s*\S", rec, re.I):
                refusals.append(f"card {c['id']}: a withheld recommendation names two options, the counts after 'standing at:', and after 'carried by:' the observation that would carry either")
        elif not chosen:
            refusals.append(f"card {c['id']}: recommended ruling names no option")
        else:
            others = [o for o in figured if o is not chosen]
            mm = re.search(r"margin:\s*([^;]+?)\s+over\s+(.+)$", rec)
            # the runner-up is the option whose name follows "over"; the line may go on after the name, separated by "; "
            tail = mm.group(2).strip() if mm else ""
            runner = max((o for o in others if tail == o["name"] or tail.startswith(o["name"] + ";") or tail.startswith(o["name"] + ".")), key=lambda o: len(o["name"]), default=None)
            if not mm:
                refusals.append(f"card {c['id']}: the Recommended line has no margin clause")
            elif not runner:
                refusals.append(f"card {c['id']}: the margin names '{mm.group(2).strip()[:50]}', which is no figured option; the runner-up's name ends the clause or is followed by '; '")
            # a value card (minutes, dollars) states its margin as the count lead behind the recommendation, since a distance between values is not evidence
            COUNT = r"\b(units?|search(es)?|asks?|enquir\w*|bookings?)\b|%"
            # a count is a number followed by what it counts, a unit of time excepted
            counted = lambda fig: re.search(r"%|(?:^|\s)[-−]?\d[\d,]*\s+(?!(?:minutes?|hours?|days?|weeks?|months?|years?|nights?)\b)[a-z]", fig.strip())
            count_lead = mm and runner and not re.search(COUNT, unit(runner["figure"])) and counted(mm.group(1))
            if mm and runner and unit(mm.group(1)) != unit(runner["figure"]) and not count_lead:
                mismatched += 1
                refusals.append(f"card {c['id']}: margin unit '{unit(mm.group(1))}' is not the runner-up's '{unit(runner['figure'])}'")
            # a count lead of one or two is erased by one operator coded the other way, which the method reads as a tie
            lead = NUM.search(mm.group(1)) if mm else None
            if lead and "%" not in mm.group(1) and "$" not in mm.group(1) and not mm.group(1).strip().startswith(("-", "−")) and num(lead.group()) <= 2 and num(lead.group()) == int(num(lead.group())):
                refusals.append(f"card {c['id']}: a lead of {lead.group()} is erased by one operator coded the other way; the method reads it as a tie, so the line is withheld or rests on a wider lead")
            if mm and runner:
                # the runner-up is the strongest other option in the chosen option's unit; a margin against a weaker one hides the front-runner
                # comparable figures: counts over the same denominator ("N of M ..."), or the same count unit; a value (minutes, dollars) is not a strength
                def denom(fig):
                    d = re.search(r"\bof\s+([\d,]+)", fig)
                    return d.group(1) if d else None
                cd, cu = denom(chosen["figure"]), unit(chosen["figure"])
                same = [o for o in others if NUM.search(o["figure"]) and denom(o["figure"]) == cd and unit(o["figure"]) == cu
                        and (cd or re.search(COUNT, cu))]
                if same:
                    strongest = max(same, key=lambda o: num(NUM.search(o["figure"]).group()))
                    if strongest is not runner:
                        refusals.append(f"card {c['id']}: margin is stated over '{runner['name']}' but '{strongest['name']}' ({strongest['figure']}) is the strongest other option; state the margin against it, negative if it is")
            # the sign of a margin follows the two figures: a recommended option with the smaller count leads by a negative number
            if mm and runner and chosen and unit(chosen["figure"]) == unit(runner["figure"]) and denom(chosen["figure"]) == denom(runner["figure"]):
                a0, b0 = NUM.search(chosen["figure"]), NUM.search(runner["figure"])
                negative = mm.group(1).strip().startswith(("-", "−"))
                if a0 and b0 and num(a0.group()) < num(b0.group()) and not negative and unit(mm.group(1)) == unit(runner["figure"]) and not re.search(r"derived on:\s*\S", rec, re.I):
                    refusals.append(f"card {c['id']}: the recommended option's figure ({chosen['figure']}) is below the runner-up's ({runner['figure']}) and the margin is written without a minus sign")
            if mm and runner and unit(mm.group(1)) == unit(runner["figure"]):
                # where both figures are plain numbers in one unit, the margin is their difference or the line says how it was derived
                a_, b_, m_ = NUM.search(chosen["figure"]), NUM.search(runner["figure"]), NUM.search(mm.group(1))
                if a_ and b_ and m_ and abs(abs(num(a_.group()) - num(b_.group())) - num(m_.group())) > 0.005 and not re.search(r"derived on:\s*\S", rec, re.I):
                    refusals.append(f"card {c['id']}: margin {m_.group()} is not {chosen['figure']} less {runner['figure']}, and the line does not say how it was derived")
        # the match is judged on the recommended option's name, which carries its value; a prevalence count is not a value
        judged = chosen["name"] if chosen else rec.split(";")[0]
        scripted = not is_withheld and prior_match(judged, c.get("Priors", ""), c["options"])
        # the priors clerk's stamp judges the match in substance; the script reads ranges and words, and where the two disagree the check says so
        stamp = re.match(r"(keeps|leaves|nothing held|held)\b", c.get("Held", "").lower())
        matched = (stamp.group(1) == "keeps" and not is_withheld) if stamp else scripted
        if stamp and not is_withheld and scripted != matched:
            print(f"NOTE card {c['id']}: the stamp says {stamp.group(1)} and the script reads {'a match' if scripted else 'no match'}")
        # staying with a held value and leaving it take the same third derivation
        is_held = stamp.group(1) != "nothing held" if stamp else ("`" in c.get("Priors", "") and not c.get("Priors", "").startswith("<"))
        rests = re.search(r"rests on:\s*(market|own buyers|both)\b", rec, re.I)
        if not is_withheld and chosen and not rests:
            refusals.append(f"card {c['id']}: the Recommended line does not say what it rests on (rests on: market, own buyers, or both)")
        counts_say = c.get("What the counts say", "")
        if not counts_say or counts_say.startswith("<"):
            refusals.append(f"card {c['id']}: no What the counts say line, the sentence the ruling sheet shows the owner")
        elif len(counts_say.split()) > 30:
            refusals.append(f"card {c['id']}: What the counts say runs to {len(counts_say.split())} words; the form asks for thirty or fewer, since the ruling sheet shows it in a cell")
        # leaving a held value rests on an instrument that could have shown the held value winning, and the line names it
        if is_held and not is_withheld and chosen and not re.search(r"seen by:\s*\S", rec, re.I):
            refusals.append(f"card {c['id']}: the line does not name, after 'seen by:', the instrument that could see both options it ranks; keeping a held value and leaving it are asked alike")
        third = [f for f in re.findall(r"`([^`]+)`", c.get("Third derivation", "")) if "third-" in Path(f).name and ((run / "3-decisions" / f).exists() or (run / f).exists())]
        withheld += is_withheld
        matches += matched
        leaves += is_held and not matched and not is_withheld
        if is_held:
            held += 1
            if third:
                returned += 1
            else:
                refusals.append(f"card {c['id']}: a value is held on this parameter and no third derivation is recorded")
        # a mark reads "<dimension>: differs" or "differs on <dimension>"; "nothing is marked differs" is not one
        differs += len(re.findall(r"(?<!marked )(?<!no )(?<!none )\bdiffers\b(?! is marked)", re.sub(r"\b(nothing|none|no \w+)( \w+){0,3} marked differs\b|\bnot marked differs\b", "", c.get("Measured in", "").lower())))
        stance = ("withheld held" if is_held else "withheld") if is_withheld else "matches" if matched else "leaves" if is_held else "none held"
        runner_name = runner["name"] if chosen and mm and runner else ""
        # a card is rewritten in place until a game brief cites its ruling; only then does a change leave a dated line
        written, cited = date_of(c.get("Written", "")), marks.get(card_key(c["id"]))
        if not written:
            refusals.append(f"card {c['id']}: no Written date, the date its evidence or recommendation was last rewritten")
        corrections = c.get("Corrections", "")
        if corrections and not corrections.startswith("<") and corrections.lower().rstrip(". ") != "none" and not cited:
            refusals.append(f"card {c['id']}: carries corrections, and no game brief cites its ruling; until one does, a change rewrites the card in place and the round's movements go to the run record")
        game = "none" if not cited else max(cited) or "undated"
        print(f"card {c['id']}: {len(figured)} figured options; prior match: {matched}; held value: {stance}; third derivation: {bool(third)}; rests on: {rests.group(1).lower() if rests else ''}; chosen: {chosen['name'] if chosen else ''} | runner-up: {runner_name} | written: {written or 'none'} | ruled on: {date_of(c.get('Ruled', '')) or 'none'} | game cites: {game}")
    outstanding = held - returned
    print(f"{len(cards)} cards; {held} hold a value; {matches} match it; {leaves} leave it; {withheld} withheld; {returned} third derivations; {outstanding} outstanding; {mismatched} mismatched margin units; {differs} legs marked differs")
    for r in refusals:
        print("REFUSED " + r)
    sys.exit(1 if refusals else 0)


if __name__ == "__main__":
    main()
