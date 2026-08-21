# Revival: the tail of the flagged list

Twenty-six modules whose gap fell outside the band but below the six handled individually. One estimator context, triage depth rather than revival depth. Read-only.

## Verdicts

| module | verdict | finding |
|---|---|---|
| `chassis/src/oracle.rs` | by design (see caveat) | "oracle" runs through the rendering discourse; 113 mentions, many in files owing nothing to this one |
| `crt-render/src/pacing.rs` | by design (see caveat) | "pacing" is generic timing vocabulary across the rendering domain, 55 mentions |
| `term/src/fonts/mod.rs` | by design | "font" appears 204 times across 31 files; central vocabulary for both display chains |
| `tmux-cc/src/ids.rs` | by design | `PaneId`/`WindowId`/`SessionId` across 14 files; protocol ids used throughout the integration |
| `crt-render/src/params.rs` | by design (see caveat) | "params" is shared vocabulary wherever a shader is parameterised |
| `chassis/src/layout.rs` | by design | layout primitives are foundational and read across the display and window subsystems |
| `crt-render/src/degauss.rs` | by design | shader-math vocabulary spread over rendering tests and implementations |
| `term/src/atlas.rs` | by design | glyph atlases are necessarily referenced across the raster/render/display layers |
| `term/src/fonts/led.rs` | by design | LED font handling used across display and test infrastructure |
| `term/src/fonts/system.rs` | by design | system-font enumeration read from several rendering contexts |
| `term/src/tmux_cc.rs` | by design | the same protocol-name sharing the `app/src/tmux.rs` revival documents |
| `tmux-cc/src/command.rs` | by design | protocol commands referenced in codec, tests and examples |
| `term/src/session.rs` | by design (see caveat) | "session" is a core protocol concept and the word travels with it |
| `term/src/search.rs` | by design (see caveat) | search vocabulary across document model, UI and tests |
| `app/src/geometry.rs` | **artefact** | 30 lines, one constant; `geometry`, `size`, `width`, `height` all filtered as common words; B=2 is the measurement floor |
| `term/src/color.rs` | **artefact** | `Rgba` dropped because both `term` and `chassis` define it; `color`, `palette`, `scheme` dropped as common words; B=1 is the filter, not the code |
| `app/src/column.rs` | **artefact** | 1307 lines drawing on 9 modules, measuring A=1 B=1. Defines `Column`, `Slot`, `ChainEntry`, `Blit`, `Out`, `Dest` — nearly all dictionary words |
| `app/src/badge.rs` | **artefact** | `Badge`, `Entry`, `Uniforms`; stem is a common noun |
| `app/src/chord.rs` | **artefact** | `Chord`, `Select`, `Store`; stem is a common noun |
| `chassis/src/displays/tape/metrics.rs` | **artefact** | every public name is common English: `unit_width`, `min_units`, `width_for_units`, `pad_cells`, `height_for_pad_cells`. B=0 is total collapse |
| `chassis/src/displays/led/metrics.rs` | **artefact** | the same pattern; B=0 structural |
| `crt-render/src/device.rs` | **artefact** | stem and vocabulary all common words; B=0 |
| `xtask/src/mask.rs` | **artefact** | same |
| `app/src/instance.rs` | **artefact** | `NewWindow` is used in 9 files; `instance` and `window` are both filtered |

## The systematic fault in the low-B group

The common-English filter overshoots. In this domain "window", "colour", "scheme", "palette", "width", "height", "select", "store", "entry", "device", "instance" *are* the vocabulary, and the filter drops them as noise. `Rgba` is dropped for a different reason — two modules define it — which removes the last distinctive name `term/src/color.rs` had. The result is modules of 30 to 1307 lines measuring B=0 or 1 despite real use.

**The B column cannot be trusted below about 8.** Above that it measures something; at the floor it measures the dictionary. Every low flag on this run's pick table should be read as "the tool had nothing to grep for", not as "well hidden".

## Caveat on the high-B half

Five of the fourteen "by design" verdicts above justify themselves in language that describes the *stem-pollution artefact* the individually-revived `chassis/src/shaders.rs` was shown to be — "the word is core to the domain discourse", "generic vocabulary across the rendering domain" — and then dispose of it as by design rather than as a measurement fault. `chassis/src/oracle.rs`, `crt-render/src/pacing.rs`, `crt-render/src/params.rs`, `term/src/session.rs` and `term/src/search.rs` are the five. Their dispositions are recorded as returned, but they were reached at triage depth and are the weakest verdicts on this run; a second pass at revival depth would likely move some of them to artefact. Nothing on this run's finding list depends on them.
