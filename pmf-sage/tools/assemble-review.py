#!/usr/bin/env python3
"""Assemble the decision review from the card files; the integrator's prose enters only through named fields.

Usage: assemble-review.py <run-dir>
Reads <run-dir>/3-decisions/**/*.md cards, <run-dir>/3-decisions/integrator-fields.md (on forms/integrator-fields.md, sections
## Unlock and ## Collisions) and <run-dir>/3-decisions/joint-ledger.md if present.
Writes <run-dir>/3-decisions/review.md from forms/review.md beside this script: the ruling sheet (one row a card), the order of
ruling, the counts from the card check, the open cards with the recommended option and its runner-up in full, the ruled cards in short, and each card's Joint line.
"""
import re, subprocess, sys
from pathlib import Path

FACE = ("Question", "Options", "Recommended")  # the line under the options table counts the silent operators once


def section(text, title):
    m = re.search(rf"^## {title}\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1).strip() if m else ""


def read_card(path):
    """The card's face by field: the line under each label, the option rows, and the Joint line."""
    card = {"file": path.name, "head": "", "fields": {}, "prose": {}, "table": [], "rows": {}, "joint": ""}
    field, in_table = None, False
    for line in path.read_text(errors="replace").splitlines():
        s = line.strip()
        fm = re.match(r"\*\*([A-Za-z ]+):?\*\*", s)
        if fm:
            field = fm.group(1)
        if s.startswith("## Card"):
            card["head"] = s
        elif s.startswith("**Options**"):
            in_table = True
        elif in_table and s.startswith("|"):
            cells = [c.strip() for c in s.strip("|").split("|")]
            if cells[0] in ("option", "---") or set(cells[0]) <= set("-: "):
                card["table"].append(s)
            else:
                card["rows"][cells[0]] = (s, cells[1] if len(cells) > 1 else "")
        elif fm:
            card["fields"].setdefault(field, s)
            in_table = False
        elif s and not fm and not s.startswith(("#", "|", "-")) and card["head"]:
            in_table = False
            # the face is the question, the options and the recommendation with what the clerk wrote beside them; prose under another field is not in the review
            if field in FACE:
                card["prose"].setdefault(field, []).append(s)
            elif field != "Cost lines":
                # the form asks for cost lines one to a line, so plain lines there are the form kept, not a paragraph lost
                print(f"DROPPED {path.name}: paragraph under {field}: {s[:70]}", file=sys.stderr)
        # the Joint line runs to the next field label or the line's end; a bullet after the label and emphasis inside the text are both the clerk's
        jm = re.search(r"\*\*Joint:\*\*\s*(?:·\s*)?(.*?)(?=\s*(?:·\s*)?\*\*[A-Za-z ]+:\*\*|$)", s)
        if jm and jm.group(1).strip():
            card["joint"] = jm.group(1).strip()
    return card


def landing(card, has_third):
    """Where the third derivation landed against the recommendation, in the card's own word."""
    # the verdict is the clause after the file; a landing split across two halves of a question keeps both words
    clauses = card["fields"].get("Third derivation", "").split(";")
    verdict = re.split(r"\.\s", clauses[1] if len(clauses) > 1 else clauses[0])[0]
    # "differs from nothing" and "declines nothing" say the opposite of the word they carry
    verdict = re.sub(r"\b(differs|declines)( \w+){0,2} (nothing|nowhere)\b|\bnowhere (differs|declines)\b", " ", verdict, flags=re.I)
    words = list(dict.fromkeys(w.lower() for w in re.findall(r"\b(agrees|differs|declines)\b", verdict, re.I)))
    if words:
        return " / ".join(words)
    if "Third derivation" in card["fields"]:
        print(f"UNSTATED {card['file']}: the Third derivation line says neither agrees, differs nor declines", file=sys.stderr)
        return "not stated"
    if not has_third:
        return "none"
    return "differs" if re.search(r"\b(diverg|did not reach|landed on a different)", card["fields"].get("Corrections", ""), re.I) else "agrees"


def with_prose(card, field):
    return [card["fields"][field]] + card["prose"].get(field, []) if field in card["fields"] else []


def main():
    run = Path(sys.argv[1]).resolve()
    here = Path(__file__).resolve().parent
    template = (here.parent / "forms" / "review.md").read_text()
    decisions = run / "3-decisions"

    def card_number(path):
        m = re.search(r"^## Card\s+(\d+)", path.read_text(errors="replace"), re.M)
        return int(m.group(1)) if m else 10**6
    cards = []
    for p in sorted((p for p in decisions.glob("**/*.md") if p.name != "review.md"), key=card_number):
        t = p.read_text(errors="replace")
        if re.search(r"^## Card\s", t, re.M) and not re.search(r"^## Third derivation", t, re.M):
            cards.append(read_card(p))

    raw = subprocess.run([sys.executable, str(here / "card-check.py"), str(run)], capture_output=True, text=True).stdout.strip()
    (decisions / "card-check.txt").write_text(raw + "\n")
    checked = {}
    for cid, match, stance, third, rests, chosen, runner in re.findall(
            r"^card (\S+):.*?prior match: (True|False); held value: ([a-z ]+); third derivation: (True|False); rests on: ([a-z ]*); chosen: (.*?) \| runner-up: (.*)$", raw, re.M):
        checked[cid] = {"match": match == "True", "stance": stance, "third": third == "True", "rests": rests, "chosen": chosen, "runner": runner}
    name = lambda c: c["head"].split(" ·")[0].replace("## ", "")
    cid_of = lambda c: re.search(r"^## Card\s+(\S+)", c["head"]).group(1).rstrip("·").strip()
    value = lambda c, f: c["fields"].get(f, "").split("**", 2)[-1].strip()

    sheet = ["| card | your part | the question | recommended | margin, or the counts it stands at | rests on | what is held | third derivation | ruled |", "|---|---|---|---|---|---|---|---|---|"]
    open_cards, ruled_cards, joints, landings = [], [], [], {}
    for c in cards:
        k = checked.get(cid_of(c), {"match": False, "stance": "", "third": False, "rests": "", "chosen": "", "runner": ""})
        rec, ruled = value(c, "Recommended"), value(c, "Ruled")
        is_ruled = bool(ruled) and ruled.lower() != "open" and not ruled.startswith("<")
        mm = re.search(r"margin:\s*([^;]+?)\s+over\s", rec)
        parts = [x.strip() for x in rec.split(";")]
        # a withheld row names the two readings it stands between, so the sheet says what is undecided
        recommended = ", ".join(parts[:2]) if parts[0].lower() == "withheld" and len(parts) > 1 and parts[1].lower().startswith("between") else parts[0]
        landings[name(c)] = landing(c, k["third"])
        held = {"matches": "keeps it", "leaves": "leaves it", "withheld held": "held; neither kept nor left", "withheld": "nothing held", "none held": "nothing held"}.get(k["stance"], "")
        title = c["head"].split("·", 1)[1].strip() if "·" in c["head"] else ""
        standing = re.search(r"standing at:\s*([^;]+)", rec, re.I)
        margin = mm.group(1) if mm else standing.group(1).strip() if standing else ""
        # beside a margin, the two figures it was taken between, so a lead of 6 to 1 and one of 27 to 26 do not read alike
        derived = re.search(r"derived on:\s*([^;]+)", rec, re.I)
        if mm and derived:
            margin += f" (derived on {derived.group(1).strip()})"
        elif mm and k["chosen"] in c["rows"] and k["runner"] in c["rows"]:
            margin += f" ({c['rows'][k['chosen']][1]} against {c['rows'][k['runner']][1]})"
        ruled_cell = ("ruled; the card leaves the ruling" if k["stance"] == "leaves" else "ruled") if is_ruled else "open"
        withheld_row = k["stance"].startswith("withheld")
        if is_ruled:
            part = "rule again, or let your ruling stand" if k["stance"] == "leaves" else "your ruling stands; read the counts in this row against it" if withheld_row else "nothing: the card agrees with your ruling"
        else:
            part = "commission the observation, or rule between the two" if withheld_row else "confirm" if k["stance"] == "matches" else "rule"
        sheet.append(f"| {cid_of(c)} | {part} | {title} | {recommended} | {margin} | {k['rests']} | {held} | {landings[name(c)]} | {ruled_cell} |")
        if c["joint"]:
            joints.append(f"{name(c)}: {c['joint']}")
        if is_ruled:
            keep = [c["head"]] + with_prose(c, "Question")[:1] + with_prose(c, "Recommended")[:1]
        else:
            # the two contenders in full; a withheld card's two readings are the options its line names
            full = [n for n in (k["chosen"], k["runner"]) if n in c["rows"]]
            if len(full) < 2:
                full = [n for n in c["rows"] if n in rec]
            table = c["table"] + [c["rows"][n][0] for n in (full if len(full) >= 2 else c["rows"])]
            rest = [f"{n} ({fig})" for n, (row, fig) in c["rows"].items() if n not in full] if len(full) >= 2 else []
            keep = ([c["head"]] + with_prose(c, "Question") + ["**Options**", "\n".join(table)]
                    + (["Other options, each with its figure: " + "; ".join(rest) + "."] if rest else []) + c["prose"].get("Options", []) + with_prose(c, "Recommended"))
        keep += [c["fields"][f] for f in ("Third derivation", "Ruled") if f in c["fields"]]
        (ruled_cards if is_ruled else open_cards).append("\n\n".join(keep))

    # the owner reads facts in words; the check's own lines stay in the run record
    m = re.search(r"(\d+) cards; (\d+) hold a value; (\d+) match it; (\d+) leave it; (\d+) withheld; (\d+) third derivations; (\d+) outstanding; (\d+) mismatched margin units; (\d+) legs marked differs", raw)
    if m:
        n, held, matches, leaves, withheld, thirds, outstanding, mism, differs = (int(x) for x in m.groups())
        part = [k for k, v in landings.items() if "/" in v]
        by = lambda w: [k for k, v in landings.items() if v == w]
        counts = (f"{n} cards. Every card offers at least two ways the market sells this, each with a figure. "
                  f"On {held} cards the venue already held a value: {matches} recommendations keep it and {leaves} leave it"
                  + (f", and {withheld} are withheld because no option is carried" if withheld else "")
                  + ". Keeping and leaving were asked for the same proof, a second derivation by a fresh clerk reading the market alone. "
                  + f"Of {thirds} such derivations, {len(by('agrees'))} agree with the first"
                  + (f", {len(by('differs'))} differ ({', '.join(by('differs'))})" if by("differs") else "")
                  + (f", {len(by('declines'))} decline to recommend ({', '.join(by('declines'))})" if by("declines") else "")
                  + (f", {len(part)} agree on one half of the question and not the other ({', '.join(part)})" if part else "") + "."
                  + (f" {outstanding} held values have no second derivation yet." if outstanding else "")
                  + (f" {mism} margins are stated in a unit other than their runner-up's." if mism else "")
                  + (f" The measured-in lines mark a measured population as differing from this venue's shape {differs} times." if differs else ""))
    else:
        counts = raw
    # a card's own words about its match must agree with the check's count of it
    for c in cards:
        k = checked.get(cid_of(c))
        if not k:
            continue
        audit = c["fields"].get("Chip", "") + " " + c["fields"].get("Corrections", "")
        if k["match"] and re.search(r"\b(did|does) not match a prior|re-derived for another reason", audit):
            print(f"MISMATCH: {name(c)} says it did not match a prior; the check counts it as matched", file=sys.stderr)
        if not k["match"] and re.search(r"\bmatched a prior on the check", audit):
            print(f"MISMATCH: {name(c)} says it matched a prior on the check; the check does not count it", file=sys.stderr)

    fields = (decisions / "integrator-fields.md").read_text(errors="replace") if (decisions / "integrator-fields.md").exists() else ""
    order = [section(fields, title) for title in ("Unlock", "Collisions")]
    order = "\n\n".join(b for b in order if b and not b.lstrip("(").lower().startswith("none"))
    # a run's joint ledger, where it keeps one, follows the order of ruling; the Joint lines stay in the card files and are read here only to check quotations
    ledger = decisions / "joint-ledger.md"
    if ledger.exists():
        order = (order + "\n\n" + ledger.read_text(errors="replace").strip()).strip()
    # a phrase the integrator credits to a card's Joint line must appear in that line verbatim; the integrator's prose has no other check
    joint_by_card = {j.split(":")[0]: j for j in joints}
    for line in order.splitlines():
        for card_ref, quoted in re.findall(r"(Card \d+)'s (?:own )?Joint line states[^\"]*\"([^\"]+)\"", line):
            if card_ref in joint_by_card and quoted not in joint_by_card[card_ref]:
                print(f"MISQUOTE: {card_ref} does not say \"{quoted[:60]}\"", file=sys.stderr)
    out = (template.replace("{{sheet}}", "\n".join(sheet) if cards else "(no cards)")
           .replace("{{order}}", order or "(the integrator named no order)")
           .replace("{{counts}}", counts or "(no cards)")
           .replace("{{cards}}", "\n\n".join(open_cards) or "(no open cards)")
           .replace("{{ruled}}", "\n\n".join(ruled_cards) or "(no card is ruled yet)"))
    (decisions / "review.md").write_text(out)
    print(f"wrote {decisions / 'review.md'} from {len(cards)} cards")


if __name__ == "__main__":
    main()
