#!/usr/bin/env python3
"""Cross-tabulate the four entry rules over the 45, and re-make each card's
option figures on the one rule. Memberships are read off each card's own
Corrections line of 2026-09-20, which names every unit in every row."""

import csv
import os

RUN = "/usr/local/src/rivermill/product-development/party-packages/2026-08-15-how-party-packages-were-decided"
TSV = os.path.join(RUN, "0-comparables", "whom-sold-to", "entry-cut.tsv")

rows = {}
with open(TSV, encoding="utf-8") as fh:
    for r in csv.DictReader(fh, delimiter="\t"):
        rows[r["profile_key"]] = r

K = list(rows)
assert len(K) == 45, len(K)

def paid(k):
    r = rows[k]
    gate = any(r[f] == "1" for f in (
        "V25_general_entry_fee", "V25_party_entry_included", "V25_party_entry_extra",
        "V25_party_adults_entry_separate", "V25_prepaid_ticket_required"))
    perhead = "per_head" in r["V7_basis_stated"].split(",")
    return gate, perhead

ASIDE = {k for k in K if any(paid(k))}
KEEP = [k for k in K if k not in ASIDE]

c11 = {k for k in K if rows[k]["on_card_11_list"] == "1"}
gate_only = {k for k in K if paid(k)[0]}
ph_only = {k for k in K if paid(k)[1]}
free_pub = {k for k in K if rows[k]["V25_entry_free"] == "1"}

print("45 units; set aside by the one rule: %d; kept: %d" % (len(ASIDE), len(KEEP)))
print("  kept r1 :", sorted(k for k in KEEP if rows[k]["cell"] == "r1"))
print("  kept r2c:", sorted(k for k in KEEP if rows[k]["cell"] == "r2c"))
print()
print("card 11's seventeen: %d" % len(c11))
print("  of them stating money at the threshold on V25: %d" % len(c11 & gate_only))
print("  of them coding a per-head party price      : %d" % len(c11 & ph_only))
print("  of them neither                            : %d  %s"
      % (len(c11 - gate_only - ph_only), sorted(c11 - gate_only - ph_only)))
print("units stating money at the threshold on V25 : %d  %s" % (len(gate_only), sorted(gate_only)))
print("units coding a per-head party price          : %d" % len(ph_only))
print("units publishing that entry is free          : %d" % len(free_pub))
print("card 11's seventeen not set aside by the rule: %s" % sorted(c11 - ASIDE))
print("set aside by the rule, not on card 11's list : %s" % sorted(ASIDE - c11))
print()

CARDS = {
 "9": {
  "a fixed session on named days": "bellas-wonderland doodlebugs-indoor-play-party-centre gold-coast-equestrian-centre jolly-jumps animal-land-childrens-farm clarks-elioak-farm odds-farm-park white-chapel-black-hall-kalbar woodside-animal-farm",
  "named days, and the hour is open": "bounce-gold-coast game-over-gold-coast magical-ponies slideways-go-karting-gold-coast topgolf-gold-coast country-magic trevena-glen-farm wattle-creek-equestrian-centre",
  "a fixed session, with no day restriction published": "city-of-gold-coast-community-venues ecopark-fishing-world-farm-stay kdv-sport timezone-robina collingwood-childrens-farm gilchrist-farm kiwi-valley-farm",
  "neither the days nor the hour published": "chipmunks-playland-robina country-paradise-parklands currumbin-rsl-waterside-events currumbin-wildlife-sanctuary event-cinemas-gold-coast fleays-wildlife-park gold-coast-turf-club old-macdonalds-travelling-farms paradise-country strike-bowling-gold-coast sunshine-coast-party-ponies the-star-gold-coast tropical-fruit-world tugun-tavern zone-bowling-surfers-paradise calgary-farmyard easton-farm-park fenek-farms hesketh-farm-park mulberry-lane-farm southlands-heritage-farm",
 },
 "10": {
  "no more than three hours": "bellas-wonderland chipmunks-playland-robina gold-coast-equestrian-centre kdv-sport slideways-go-karting-gold-coast strike-bowling-gold-coast topgolf-gold-coast magical-ponies easton-farm-park kiwi-valley-farm trevena-glen-farm wattle-creek-equestrian-centre white-chapel-black-hall-kalbar doodlebugs-indoor-play-party-centre game-over-gold-coast clarks-elioak-farm country-magic gilchrist-farm southlands-heritage-farm sunshine-coast-party-ponies tropical-fruit-world animal-land-childrens-farm calgary-farmyard odds-farm-park woodside-animal-farm",
  "more than three hours": "ecopark-fishing-world-farm-stay collingwood-childrens-farm",
  "no length published at all": "bounce-gold-coast city-of-gold-coast-community-venues country-paradise-parklands currumbin-rsl-waterside-events currumbin-wildlife-sanctuary event-cinemas-gold-coast fleays-wildlife-park gold-coast-turf-club old-macdonalds-travelling-farms paradise-country the-star-gold-coast tugun-tavern zone-bowling-surfers-paradise fenek-farms hesketh-farm-park mulberry-lane-farm",
  "(undecidable)": "jolly-jumps timezone-robina",
 },
 "12": {
  "a host is named as included": "bellas-wonderland bounce-gold-coast chipmunks-playland-robina currumbin-rsl-waterside-events doodlebugs-indoor-play-party-centre kdv-sport magical-ponies slideways-go-karting-gold-coast strike-bowling-gold-coast timezone-robina topgolf-gold-coast tugun-tavern zone-bowling-surfers-paradise animal-land-childrens-farm clarks-elioak-farm country-magic easton-farm-park fenek-farms gilchrist-farm kiwi-valley-farm mulberry-lane-farm southlands-heritage-farm wattle-creek-equestrian-centre",
  "a host is refused in the venue's own words": "game-over-gold-coast odds-farm-park",
  "neither stated": "city-of-gold-coast-community-venues country-paradise-parklands currumbin-wildlife-sanctuary ecopark-fishing-world-farm-stay event-cinemas-gold-coast fleays-wildlife-park gold-coast-equestrian-centre gold-coast-turf-club jolly-jumps paradise-country the-star-gold-coast tropical-fruit-world calgary-farmyard collingwood-childrens-farm hesketh-farm-park trevena-glen-farm white-chapel-black-hall-kalbar woodside-animal-farm",
  "(undecidable)": "old-macdonalds-travelling-farms sunshine-coast-party-ponies",
 },
 "13": {
  "a private area inside a site that stays open around it": "bounce-gold-coast chipmunks-playland-robina currumbin-rsl-waterside-events fleays-wildlife-park gold-coast-equestrian-centre strike-bowling-gold-coast the-star-gold-coast topgolf-gold-coast tropical-fruit-world tugun-tavern clarks-elioak-farm collingwood-childrens-farm country-magic easton-farm-park gilchrist-farm odds-farm-park white-chapel-black-hall-kalbar woodside-animal-farm",
  "a reserved area, not stated to be private": "game-over-gold-coast gold-coast-turf-club kdv-sport timezone-robina zone-bowling-surfers-paradise animal-land-childrens-farm hesketh-farm-park mulberry-lane-farm southlands-heritage-farm trevena-glen-farm wattle-creek-equestrian-centre",
  "the whole venue, exclusive to the party": "bellas-wonderland country-paradise-parklands doodlebugs-indoor-play-party-centre event-cinemas-gold-coast slideways-go-karting-gold-coast fenek-farms",
  "a space the text states is shared with another party": "kiwi-valley-farm",
  "(outside every row)": "city-of-gold-coast-community-venues currumbin-wildlife-sanctuary ecopark-fishing-world-farm-stay paradise-country jolly-jumps magical-ponies old-macdonalds-travelling-farms sunshine-coast-party-ponies calgary-farmyard",
 },
 "22": {
  "open permission to bring food": "ecopark-fishing-world-farm-stay calgary-farmyard clarks-elioak-farm collingwood-childrens-farm country-magic gilchrist-farm hesketh-farm-park kiwi-valley-farm mulberry-lane-farm trevena-glen-farm wattle-creek-equestrian-centre",
  "permission for a cake only": "chipmunks-playland-robina kdv-sport timezone-robina topgolf-gold-coast easton-farm-park",
  "a prohibition published, the cake excepted": "game-over-gold-coast tugun-tavern odds-farm-park woodside-animal-farm",
  "a permission and a prohibition published together": "bellas-wonderland doodlebugs-indoor-play-party-centre",
 },
 "11": {
  "the animals are inside the party price": "animal-land-childrens-farm clarks-elioak-farm country-magic easton-farm-park fenek-farms gilchrist-farm hesketh-farm-park kiwi-valley-farm mulberry-lane-farm odds-farm-park southlands-heritage-farm trevena-glen-farm wattle-creek-equestrian-centre woodside-animal-farm",
  "the animals are priced beside the party, module by module": "collingwood-childrens-farm",
  "no animal element in the party offer at all": "calgary-farmyard white-chapel-black-hall-kalbar",
 },
}

for cid, opts in CARDS.items():
    print("card %s" % cid)
    covered = set()
    for name, units in opts.items():
        u = set(units.split())
        assert u <= set(K), (cid, name, u - set(K))
        covered |= u
        kept = u - ASIDE
        print("   %-56s all 45: %2d   kept: %2d" % (name[:56], len(u), len(kept)))
    if cid != "22" and cid != "11":
        assert len(covered) == 45, (cid, len(covered))
    print("   silent/remainder                                       all 45: %2d   kept: %2d"
          % (45 - len(covered), len(set(K) - covered - ASIDE)))
    print()
