import re,os,json,glob
D='/usr/local/src/rivermill/product-development/school-excursion/2026-08-10-how-the-river-day-was-decided/0-comparables/school-programmes-2026-08/venues'
FIELDS=['activities_verbatim','programme_names','child_safety_checks_stated','title_and_opening_line','testimonials_from_schools','teacher_materials','staff_qualifications_stated','school_offer_detail_level','risk_assessment_available','price_visible_without_asking','price_and_structure','participant_thresholds','insurance_stated','how_to_book','group_size_min_max','facilities','equipment_provided','duration','downloadable_pack','curriculum_links','catering','cancellation_and_weather','booking_lead_time','animal_species_held','adults_free_ratio','accreditations_displayed','accessibility_provision']
pat=re.compile(r'^[-*# ]*\*{0,2}('+'|'.join(FIELDS)+r')\*{0,2}\s*:?\s*(.*)$')
out={}
for f in sorted(glob.glob(D+'/*.md')):
    txt=open(f).read().split('\n')
    cur=None; d={}
    for line in txt:
        m=pat.match(line)
        if m:
            cur=m.group(1); d.setdefault(cur,[]).append(m.group(2))
        elif cur is not None:
            if pat.match(line): pass
            d[cur].append(line)
    out[os.path.basename(f)[:-3]]={k:'\n'.join(v).strip() for k,v in d.items()}
json.dump(out,open('/tmp/claude-1000/-usr-local-src-aesop-pmf-sage/71556939-dbe7-4408-8703-686f4079d0ba/scratchpad/venues.json','w'))
print(len(out))
import collections
print(collections.Counter(len(v) for v in out.values()))
