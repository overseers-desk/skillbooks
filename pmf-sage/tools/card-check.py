#!/usr/bin/env python3
"""Count what a card set must carry before it reaches the owner, and refuse what falls short.

Usage: card-check.py <run-dir>
Reads every card under <run-dir>/3-decisions/ written on forms/card.md.
Refuses: fewer than two options carrying a figure; a recommendation naming no option or stating its
margin in a unit other than the runner-up's, or not the difference of the two figures unless the line states its derivation, or stated against an option weaker than the strongest other; a withheld recommendation that does not name
two options, the counts it stands at and the observation that would carry either; a recommending line that does not say what it rests on; a held value (the Held stamp, or without one a Priors line citing a file) with no third derivation recorded (a backticked third-derivation file, on the Third derivation line or the Corrections line, that exists).
Reports: figured options per card; recommendations that match a held value, leave one, or are withheld, as counts and no more; mismatched margin units; legs marked differs.
"""
import re, sys
from pathlib import Path

NUM = re.compile(r"\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?")


def num(tok):
    return float(tok.replace(",", ""))
STOP = {"the", "and", "with", "from", "that", "this", "over", "into", "than", "each", "about"}


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
    in_table = False
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
        for key in ("Recommended", "Held", "Priors", "Measured in", "Ruled", "Third derivation", "Corrections"):
            if s.startswith(f"**{key}:**"):
                card[key] = s.split("**", 2)[2].strip()
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
    shared = {w for w in re.findall(r"[a-z]{4,}", " ".join(o["name"].lower() for o in options))
              if sum(w in o["name"].lower() for o in options) >= 2}
    words = {w for w in re.findall(r"[a-z]{4,}", priors.lower())} - STOP - shared
    return any(w in recommended.lower() for w in words)


def main():
    run = Path(sys.argv[1]).resolve()
    cards = [parse(p.read_text(errors="replace")) for p in sorted((run / "3-decisions").glob("**/*.md"))
             if p.name != "review.md" and re.search(r"^## Card\s", p.read_text(errors="replace"), re.M)
             and not re.search(r"^## Third derivation", p.read_text(errors="replace"), re.M)]
    refusals, matches, leaves, withheld, held, returned, mismatched, differs = [], 0, 0, 0, 0, 0, 0, 0
    if not cards:
        print("REFUSED no card on forms/card.md found under 3-decisions/ (a `## Card N` heading per card)")
        sys.exit(1)
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
                refusals.append(f"card {c['id']}: the standing-at clause runs to {len(standing.group(1).split())} words; the form asks for twenty or fewer, the rest belongs in the corrections")
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
            COUNT = r"\b(units?|walks?|places?|programmes?|search(es)?|asks?|enquir\w*|bookings?)\b|%"
            count_lead = mm and runner and not re.search(COUNT, unit(runner["figure"])) and re.search(COUNT, unit(mm.group(1)))
            if mm and runner and unit(mm.group(1)) != unit(runner["figure"]) and not count_lead:
                mismatched += 1
                refusals.append(f"card {c['id']}: margin unit '{unit(mm.group(1))}' is not the runner-up's '{unit(runner['figure'])}'")
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
            if mm and runner and unit(mm.group(1)) == unit(runner["figure"]):
                # where both figures are plain numbers in one unit, the margin is their difference or the line says how it was derived
                a_, b_, m_ = NUM.search(chosen["figure"]), NUM.search(runner["figure"]), NUM.search(mm.group(1))
                if a_ and b_ and m_ and abs(abs(num(a_.group()) - num(b_.group())) - num(m_.group())) > 0.005 and not tail[len(runner["name"]):].strip(" ;."):
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
        # leaving a held value rests on an instrument that could have shown the held value winning, and the line names it
        if is_held and not matched and not is_withheld and chosen and not re.search(r"seen by:\s*\S", rec, re.I):
            refusals.append(f"card {c['id']}: the line leaves a held value and does not name, after 'seen by:', the instrument that could have shown the held value winning")
        third = [f for f in re.findall(r"`([^`]+)`", c.get("Third derivation", "") + " " + c.get("Corrections", "")) if "third-" in Path(f).name and ((run / "3-decisions" / f).exists() or (run / f).exists())]
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
        print(f"card {c['id']}: {len(figured)} figured options; prior match: {matched}; held value: {stance}; third derivation: {bool(third)}; rests on: {rests.group(1).lower() if rests else ''}; chosen: {chosen['name'] if chosen else ''} | runner-up: {runner_name}")
    outstanding = held - returned
    print(f"{len(cards)} cards; {held} hold a value; {matches} match it; {leaves} leave it; {withheld} withheld; {returned} third derivations; {outstanding} outstanding; {mismatched} mismatched margin units; {differs} legs marked differs")
    for r in refusals:
        print("REFUSED " + r)
    sys.exit(1 if refusals else 0)


if __name__ == "__main__":
    main()
