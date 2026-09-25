import re, pathlib

p = pathlib.Path("priors-pass.md")
t = p.read_text()

old_status = re.search(r'^status: ".*?"$', t, re.M).group(0)
new_status = (
    'status: "Opens the fenced files this run\'s own decisions carry: `3-decisions/2026-08-10-decision-review.md`, the decisions '
    'table of `4-product-design/2026-08-10-school-excursion-product-definition.md`, and `sot/S2-fees-and-service-hours.md` §5.10. Ran after all '
    'thirty cards were written and before the four corrections passes of 2026-09-19, so the table below is the record of what this pass found and '
    'not of where the set now stands; each row that has since turned or been withheld says so in its recommendation cell, and the rest of the row '
    'stands as this pass wrote it. What moved in the fourth and last pass, which ran the instrument test and the one-operator test over every line '
    'alike rather than over the departures only: of the fourteen recommendations then keeping a held value, thirteen stood under those tests; card 2 '
    'fell from a departure to withheld, its search leg holding a row for one of the two options it was asked to rank and none for the other; card 22 '
    'turned from withheld to a stated minimum party size, which leaves the owner\'s ruling of 14 August 2026; and card 9 followed card 22 to a floor '
    'and a ceiling together, leaving the same ruled value in the same act. Those two are one departure on one parameter, stamped on both cards that '
    'carry a half of it, and his ruling stands on both until he rules again. A withheld card on a parameter he has ruled now puts its counts to him '
    'with the ruled value\'s count first. The card form carries a Held line stamped in substance by the priors clerk, which is what the counts below '
    'are read from; `python3 tools/card-check.py` keeps its own narrower word rule and prints a NOTE where the two disagree, on six cards '
    '(4, 5, 14, 16, 22, 24). As the set stands, 29 of the 30 cards hold a value, 13 recommendations keep it, 5 leave it, 12 are withheld, 29 third '
    'derivations answer the 29 held values and none is outstanding (`3-decisions/card-check.txt`)."'
)
assert old_status in t
t = t.replace(old_status, new_status)

t = re.sub(r" \((?:withheld|turned) as at 2026-09-19[^)]*\)", "", t)

marks = {
    "0": " (turned as at 2026-09-19 to a thin recommendation for this same option, on the 48 Australian profiles two codings place alike)",
    "2": " (withheld as at 2026-09-19, between the buyer's word and the venue's own name, the search leg having no row for the option it was ranked against)",
    "3": " (withheld as at 2026-09-19)",
    "7": " (turned as at 2026-09-19 to a thin recommendation for this same option, on the 48 Australian profiles two codings place alike)",
    "9": " (turned as at 2026-09-19 to a floor and a ceiling together, following card 22 and leaving the ruled no-minimum with it)",
    "10": " (withheld as at 2026-09-19)",
    "13": " (withheld as at 2026-09-19)",
    "14": " (turned as at 2026-09-19 to a subject or syllabus named, with no codes, which the Held line reads as the owner's ruling in substance)",
    "18": " (withheld as at 2026-09-19, the count behind the turn having been made twice and disagreed)",
    "19": " (withheld as at 2026-09-19)",
    "20": " (withheld as at 2026-09-19)",
    "21": " (withheld as at 2026-09-19, between this option and the ruled paid line beside the packed lunch)",
    "22": " (turned as at 2026-09-19 to a stated minimum party size, which leaves the ruling of 14 August)",
    "23": " (withheld as at 2026-09-19)",
    "27": " (withheld as at 2026-09-19)",
    "28": " (withheld as at 2026-09-19, between this option and the ruled free familiarisation visit)",
    "29": " (withheld as at 2026-09-19)",
}

out = []
marked = 0
for line in t.splitlines():
    m = re.match(r"\| (\d+) ", line)
    if m and m.group(1) in marks:
        cells = line.split(" | ")
        cells[1] = cells[1].rstrip() + marks[m.group(1)]
        line = " | ".join(cells)
        marked += 1
    out.append(line)

p.write_text("\n".join(out) + "\n")
print("status rewritten; rows marked:", marked)
