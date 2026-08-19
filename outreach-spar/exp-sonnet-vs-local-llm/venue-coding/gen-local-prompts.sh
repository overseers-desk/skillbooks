#!/bin/sh
# Build chunked-group and facts-fed prompts for the local models.
S="$(cd "$(dirname "$0")" && pwd)"
CB=/home/weiwu/code/rivermill/product-development/weddings/2026-08-15-wedding-survey/2-codebook/codebook.md
MD=/home/weiwu/code/rivermill/product-development/weddings/data/2026-08-19-australian-wedding-venue-corpus/md
sec () { sed -n "${2},${3}p" "$CB" > "$S/local-prompts/sec-$1.md"; }
sec price 400 518      # V6, V7, V8
sec money 519 563      # V9
sec offer 226 348      # V1, V2, V3, V4
sec routes 1094 1164   # V21, V22
strip () { awk 'f; /^---$/{c++; if(c==2) f=1}' "$MD/$1.md" > "$S/local-prompts/$1.body.md"; }
ex () { grep -niE -A "$2" "$3" "$S/local-prompts/$1.body.md" | head -"$4"; }
for V in "$@"; do
  strip "$V"
  ex "$V" 2 '\$[0-9]|per (person|head|guest)|\bpp\b|pricing|price|minimum spend|package price|venue hire|site fee' 150 > "$S/local-prompts/$V.ex-price.txt"
  ex "$V" 2 'deposit|bond|payment|instalment|cancel|refund|surcharge|service charge|final numbers' 100 > "$S/local-prompts/$V.ex-money.txt"
  ex "$V" 1 '^## PAGE|package|ceremony|reception|elopement|micro|capacity|guests|seated|cocktail|marquee|chapel|barn|garden|accommodat' 160 > "$S/local-prompts/$V.ex-offer.txt"
  ex "$V" 1 '^## PAGE|enquir|contact|tour|site visit|viewing|open day|form|phone|email|appointment|brochure|get in touch|book' 130 > "$S/local-prompts/$V.ex-routes.txt"
  for G in price money offer routes; do
    { printf 'You are a content-analysis coder. Below is one section of a frozen codebook, then numbered excerpt lines from one wedding venue website capture (line format NUMBER:TEXT; ## PAGE lines mark page boundaries and their URLs).\n\nApply ONLY the variables defined in this codebook section, exactly as its rules state. Text-only coding: no inference, no arithmetic, no outside knowledge. Silence is 0. Unclear text is 8. Output ONLY tab-separated lines, one per coded field, format:\nFIELD\tENTITY\tVALUE\tQUOTE\nENTITY is the offer or package name the field belongs to, or - for venue-level. VALUE per the section (1, 8, a band number, or verbatim for *_verbatim fields; omit 0 fields entirely). QUOTE is the deciding passage copied exactly from an excerpt line, or empty after the tab for value 8 explained in a trailing note line NOTE\t<field>\t<why>. For every monetary figure output also a line:\nAMOUNT\t<figure exactly as written>\t<what it buys>\t<conditions>\nNo prose, no explanation, no markdown.\n\n=== CODEBOOK SECTION ===\n'
      cat "$S/local-prompts/sec-$G.md"
      printf '\n=== VENUE EXCERPTS (%s) ===\n' "$V"
      cat "$S/local-prompts/$V.ex-$G.txt"
      printf '\n=== OUTPUT ===\n'
    } > "$S/local-prompts/$V.$G.prompt"
  done
  # facts-fed: one compact sheet, fixed questionnaire
  { printf 'You are a content-analysis coder. Below is a fact sheet of numbered excerpt lines from one wedding venue website. Answer the questionnaire from these lines only. No inference, no arithmetic. Silence means not stated.\n\n=== FACT SHEET (%s) ===\n' "$V"
    sort -u -t: -k1,1n "$S/local-prompts/$V.ex-price.txt" "$S/local-prompts/$V.ex-money.txt" "$S/local-prompts/$V.ex-offer.txt" "$S/local-prompts/$V.ex-routes.txt" | head -260
    printf '\n=== QUESTIONNAIRE ===\nOutput ONLY these tab-separated answer lines, nothing else:\nV6_value\t<5 complete price published|4 banded prices only|3 from-price or range|2 no number but a price route stated|1 money never mentioned> as the digit\nV6_quote\t<the deciding passage copied exactly>\nAMOUNT\t<each monetary figure exactly as written>\t<what it buys>\t<conditions> (one line per figure; none if no figures)\nV4_max_band\t<highest stated guest capacity banded: 1=1-20 2=21-50 3=51-100 4=101-150 5=151-250 6=251-400 7=over 400 0=none stated>\nV4_quote\t<the capacity passage exactly, or empty>\nOFFER\t<each named wedding package, tier or hired space, exactly as named> (one line per offer)\nV21_routes\t<comma list from: form,email,phone,pack_request,online_booking,none stated>\nV22_tour\t<by_appointment|online_booking|open_day|not stated>\nV28_response_promise\t<the response-time wording exactly, or: not stated>\nV9_deposit\t<1 if a deposit is stated, else 0>\tV9_quote\t<passage or empty>\n' 
  } > "$S/local-prompts/$V.facts.prompt"
done
wc -c "$S"/local-prompts/*.prompt | tail -3
