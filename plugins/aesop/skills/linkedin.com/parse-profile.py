#!/usr/bin/env python3
"""Parse a LinkedIn profile page HTML into a structured YAML record.

Usage: python3 parse-profile.py <html-file> [profile-url-or-slug]

LinkedIn's DOM uses randomised class names and lazy-mounts deep sections
(career history, About, skills) after load, so reliable extraction is limited
to identity, the member URN, and the topcard. We extract:

  1. name        — <title> is always "Name | LinkedIn"
  2. urn         — urn:li:fsd_profile:ACoAA...  (the stable profile handle a
                   later connection campaign keys on)
  3. member_id   — urn:li:member:NNN  (legacy numeric form of the same person)
  4. headline / location / current_company — best-effort from meta + topcard
  5. evidence_blocks — a capped list of cleaned visible-text fragments, kept so
                   the verification step (and a human) can confirm identity

The page carries several people's URNs (the signed-in viewer, "people also
viewed"). The profile owner is the most-frequently-referenced URN, since the
page is about them; this is how the owner is disambiguated from the rest.

Output is YAML on stdout. The caller redirects it to <slug>.yaml.
"""

import re
import sys
from collections import Counter
from html import unescape

import yaml


def strip_viewer_content(html):
    """Remove the signed-in viewer's own profile data from the page.

    LinkedIn embeds the viewer's profile in <nav> and <aside> elements; without
    this, text from those sections pollutes the target profile's blocks. Used
    only for the visible-text extraction, not for URN counting (the owner
    dominates the raw page regardless).
    """
    html = re.sub(r'<nav\b[^>]*>.*?</nav>', '', html, flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<aside\b[^>]*>.*?</aside>', '', html, flags=re.DOTALL | re.IGNORECASE)
    for marker in [
        "People also viewed",
        "People you may know",
        "You might also know",
        "Explore collaborative articles",
        "Add profile section",
        "More profiles for you",
        "Seleccionar idioma",
        "Select Language",
        "Más información sobre el contenido recomendado",
        "Learn more about recommended content",
    ]:
        idx = html.find(marker)
        if idx > 5000:
            html = html[:idx]
            break
    return html


def slug_from_arg(arg):
    """Derive the vanity slug from a profile URL or a bare slug argument."""
    if not arg:
        return None
    m = re.search(r'/in/([^/?#]+)', arg)
    return m.group(1) if m else arg.strip().strip('/')


def slug_from_dom(html):
    """Fallback: recover the slug from a componentkey when no arg is passed."""
    m = re.search(r'(?:ProfilePostConnectDrawer|profile_education_top_anchor_)([a-z0-9-]+)', html)
    return m.group(1) if m else None


def owner_urn(html):
    """Return the owner's fsd_profile URN (urn:li:fsd_profile:ACoAA...), or None.

    The fsd profile id is the ACoAA... token, which LinkedIn serialises several
    ways in one dump: urn:li:fsd_profile:ACoAA..., url-encoded fsd_profile%3AACoAA...,
    profileId=ACoAA..., and React component keys that append a PascalCase suffix
    (ACoAA...ExperienceTopLevel). The canonical id is a fixed 39-char token (ACoAA
    + 34); truncating every match to 39 chars collapses the suffixed component-key
    variants onto it, so the owner dominates the count over other people on the page
    (message recipients, "people also viewed"), which appear only a handful of times.

    The legacy numeric form (urn:li:member:NNN) is deliberately not returned: on a
    profile page its most-frequent value is the signed-in viewer's own account id
    (it saturates the nav/messaging chrome), not the profile owner, so it cannot be
    read off the DOM reliably. The fsd_profile URN is the handle the connection API
    keys on (inviteeMember/inviteeProfile), which is what a later campaign needs.
    """
    tokens = re.findall(r'ACoAA[A-Za-z0-9_-]+', html)
    if not tokens:
        return None
    base = Counter(t[:39] for t in tokens).most_common(1)[0][0]
    return f"urn:li:fsd_profile:{base}"


def meta_content(html, tag):
    """Read a <meta> value, tolerating either attribute order."""
    pat1 = re.findall(rf'<meta[^>]*(?:name|property)="{tag}"[^>]*content="([^"]*)"', html)
    pat2 = re.findall(rf'<meta[^>]*content="([^"]*)"[^>]*(?:name|property)="{tag}"', html)
    val = (pat1 or pat2 or [None])[0]
    return unescape(val) if val else None


def extract_visible_texts(html):
    """Extract visible text fragments from the obfuscated DOM, filtering noise."""
    raw = re.findall(r">([^<]{10,500})<", html)
    noise_patterns = [
        r"^\s*\{", r"^\s*\.", r"^\s*var ", r"^\s*function", r"width:", r"padding",
        r"margin:", r"font-", r"display:", r"background", r"border", r"position:",
        r"overflow", r"opacity", r"color:", r"transform", r"transition", r"animation",
        r"z-index", r"box-shadow", r"text-decoration", r"line-height", r"letter-spacing",
        r"white-space", r"flex", r"grid", r"align-", r"justify-", r"cursor:", r"visibility",
        r"pointer-events", r"componentkey", r"data-display", r"tabindex", r"aria-",
        r"\.video-js", r"vjs-", r"_[0-9a-f]{8}",
    ]
    filtered, seen = [], set()
    for text in raw:
        text = unescape(text.strip())
        if not text or text in seen:
            continue
        if any(re.search(p, text) for p in noise_patterns):
            continue
        if any(n in text for n in UI_NOISE):
            continue
        seen.add(text)
        filtered.append(text)
    return filtered


ROLE_KW = (" at ", "Director", "Manager", "CEO", "Founder", "Chairman", "Partner",
           "Consultant", "Engineer", "Analyst", "President", "Owner", "Principal",
           "Coordinator", "Officer", "Specialist", "Lead", "Head of", "Executive",
           "Influencer", "Creator", "Coach", "Celebrant", "Photographer", "Planner",
           "Adviser", "Advisor", "Agent", "Producer", "Editor", "Journalist",
           "Teacher", "Chef", "Designer", "Speaker", "Stylist", "Therapist")

UI_NOISE = ("notificaci", "Enviar mensaje", "Información de contacto", "seguidores",
            "contactos en común", "LinkedIn Corporation", "Centro de ayuda",
            "Configuración", "Pasar a", "Ir al contenido", "Skip to", "Más de",
            "recomendaciones", "preguntas", "privacidad", "contact info", "followers",
            "la búsqueda", "al margen", "pie de página", "Notifications", "Mensaje",
            "Acceso", "Únete ahora", "Iniciar sesión", "mutual connection")

PLACE = re.compile(r'(?i)\b('
    r'Australia|Queensland|New South Wales|Victoria|Tasmania|Western Australia|'
    r'South Australia|Northern Territory|Brisbane|Sydney|Melbourne|Perth|Adelaide|'
    r'Canberra|Hobart|Darwin|Gold Coast|Sunshine Coast|Cairns|Townsville|Toowoomba|'
    r'United States|United Kingdom|England|Scotland|Wales|Ireland|Singapore|'
    r'New Zealand|Canada|Saudi|Arabia|Emirates|Dubai|France|Germany|Italy|Spain|'
    r'Netherlands|India|Japan|China|Hong Kong|Philippines|Indonesia|Malaysia|'
    # Spanish-rendered place names (the session locale renders foreign regions in Spanish)
    r'Reino Unido|Inglaterra|Escocia|Gales|Irlanda|Estados Unidos|Alemania|Francia|'
    r'España|Italia|Singapur|Nueva Zelanda|Canadá|Japón|Países Bajos|Arabia Saudí|'
    r'Emiratos|Filipinas|Malasia|Indonesia|Reino|Suiza|Bélgica|Suecia'
    r')\b')


def infer_headline(texts, name):
    """The headline is the first content block after the name that names a role or
    uses a credential separator. UI chrome and the name/title lines are skipped."""
    for t in texts:
        if t == name or "| LinkedIn" in t or len(t) < 12:
            continue
        if any(n in t for n in UI_NOISE):
            continue
        if any(kw in t for kw in ROLE_KW) or " | " in t:
            return t
    return None


def infer_location(texts, name):
    """Pick the first short block that names a known place. A geographic word is a
    far more reliable signal than a generic "Word, Word" pattern, which a headline
    like "Theme Parks, Resorts" also matches."""
    for t in texts:
        if len(t) < 80 and t != name and "| LinkedIn" not in t and PLACE.search(t):
            return t
    return None


def current_company(headline):
    if headline and " at " in headline:
        return headline.split(" at ", 1)[1].strip()
    return None


def parse_profile(html_path, url_arg=None):
    with open(html_path, "r") as f:
        html = f.read()

    title_match = re.findall(r"<title[^>]*>(.*?)</title>", html, re.DOTALL)
    title = title_match[0].strip() if title_match else ""
    if any(t in title.lower() for t in ["sign in", "log in", "iniciar", "registrarse"]):
        print("ERROR: LinkedIn session expired. Log in via a Chrome-compatible browser first.",
              file=sys.stderr)
        sys.exit(1)

    name = title.replace(" | LinkedIn", "").strip() if " | LinkedIn" in title else title

    fsd_urn = owner_urn(html)

    slug = slug_from_arg(url_arg) or slug_from_dom(html)
    if url_arg and url_arg.startswith("http"):
        profile_url = url_arg
    elif slug:
        profile_url = f"https://www.linkedin.com/in/{slug}/"
    else:
        profile_url = None

    texts = extract_visible_texts(strip_viewer_content(html))
    og_desc = meta_content(html, "og:description") or meta_content(html, "description")
    headline = infer_headline(texts, name)

    record = {
        "slug": slug,
        "profile_url": profile_url,
        "urn": fsd_urn,
        "name": name or None,
        "headline": headline,
        "meta_description": (og_desc[:500] if og_desc else None),
        "location": infer_location(texts, name),
        "current_company": current_company(headline),
        "evidence_blocks": texts[:15],
    }

    yaml.safe_dump(record, sys.stdout, allow_unicode=True, sort_keys=False,
                   default_flow_style=False, width=1000)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <profile.html> [profile-url-or-slug]", file=sys.stderr)
        sys.exit(1)
    parse_profile(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
