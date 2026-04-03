#!/usr/bin/env python3
"""Convert events YAML to a sortable HTML table."""

import yaml
import html
import sys
from pathlib import Path

def load_events(path):
    with open(path) as f:
        return yaml.safe_load(f)["events"]

def render_html(events):
    rows = []
    for e in events:
        date_start = e.get("date_start") or ""
        date_end = e.get("date_end") or ""
        date_display = str(date_start)
        if date_end and date_end != date_start:
            date_display += f" — {date_end}"
        if not date_start:
            date_display = "TBC"

        loc = e.get("location", {})
        city = loc.get("city", "")
        country = loc.get("country", "")
        location = f"{city}, {country}" if city else ""

        stars = e.get("stars", 0)
        star_display = "★" * stars + "☆" * (5 - stars)

        cats = ", ".join(e.get("categories", []))

        status = (e.get("participation") or {}).get("status") or "—"
        spk = e.get("speaker", {})
        spk_late = spk.get("too_late", False)
        spk_deadline = spk.get("deadline") or ""
        speaker_info = "too late" if spk_late else str(spk_deadline) if spk_deadline else "open"

        url = e.get("url", "")
        name = e.get("name", "")
        name_html = f'<a href="{html.escape(url)}">{html.escape(name)}</a>' if url else html.escape(name)

        notes = html.escape(e.get("notes", ""))

        # sort keys as data attributes
        sort_date = str(date_start) if date_start else "9999-12-31"

        rows.append(
            f'<tr data-stars="{stars}" data-date="{sort_date}" data-location="{html.escape(city)}">'
            f'<td class="stars">{star_display}</td>'
            f"<td>{name_html}</td>"
            f"<td>{html.escape(date_display)}</td>"
            f"<td>{html.escape(location)}</td>"
            f"<td>{html.escape(cats)}</td>"
            f"<td>{html.escape(status)}</td>"
            f"<td>{html.escape(speaker_info)}</td>"
            f'<td class="notes">{notes}</td>'
            f"</tr>"
        )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Almanac — Events 2026</title>
<style>
  body {{ font-family: system-ui, sans-serif; margin: 2em; background: #fafafa; }}
  h1 {{ font-size: 1.4em; }}
  table {{ border-collapse: collapse; width: 100%; font-size: 0.85em; }}
  th, td {{ border: 1px solid #ddd; padding: 6px 10px; text-align: left; vertical-align: top; }}
  th {{ background: #333; color: #fff; cursor: pointer; user-select: none; position: sticky; top: 0; }}
  th:hover {{ background: #555; }}
  th .arrow {{ font-size: 0.7em; margin-left: 4px; }}
  tr:nth-child(even) {{ background: #f4f4f4; }}
  .stars {{ color: #e6a817; font-size: 1.1em; white-space: nowrap; }}
  .notes {{ max-width: 320px; font-size: 0.8em; color: #555; }}
  a {{ color: #1a6fb5; text-decoration: none; }}
  a:hover {{ text-decoration: underline; }}
  tr[data-stars="5"] {{ background: #fef9e7; }}
  tr[data-stars="5"]:nth-child(even) {{ background: #fdf3cd; }}
</style>
</head>
<body>
<h1>Almanac — Events 2026</h1>
<p>Click column headers to sort.</p>
<table id="events">
<thead>
<tr>
  <th data-sort="stars">Stars <span class="arrow"></span></th>
  <th>Name</th>
  <th data-sort="date">Date <span class="arrow"></span></th>
  <th data-sort="location">Location <span class="arrow"></span></th>
  <th>Categories</th>
  <th>Status</th>
  <th>Speaker</th>
  <th>Notes</th>
</tr>
</thead>
<tbody>
{"".join(rows)}
</tbody>
</table>
<script>
document.querySelectorAll("th[data-sort]").forEach(th => {{
  th.addEventListener("click", () => {{
    const key = th.dataset.sort;
    const tbody = document.querySelector("#events tbody");
    const rows = Array.from(tbody.rows);
    const arrow = th.querySelector(".arrow");
    const asc = arrow.textContent !== "\\u25b2";
    document.querySelectorAll("th .arrow").forEach(a => a.textContent = "");
    arrow.textContent = asc ? "\\u25b2" : "\\u25bc";
    rows.sort((a, b) => {{
      let va = a.dataset[key], vb = b.dataset[key];
      if (key === "stars") {{ va = +va; vb = +vb; return asc ? va - vb : vb - va; }}
      return asc ? va.localeCompare(vb) : vb.localeCompare(va);
    }});
    rows.forEach(r => tbody.appendChild(r));
  }});
}});
</script>
</body>
</html>"""

if __name__ == "__main__":
    src = Path(__file__).parent / "2026.yaml"
    if len(sys.argv) > 1:
        src = Path(sys.argv[1])
    out = src.with_suffix(".html")
    out.write_text(render_html(load_events(src)))
    print(f"Written to {out}")
