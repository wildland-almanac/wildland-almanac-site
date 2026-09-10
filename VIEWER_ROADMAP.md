# COG viewer — roadmap for an in-house fork

**Status: investigated 2026-09-09, deliberately tabled.** No low-hanging fruit was found; every
feature below needs us to host our own build first, so there is no cheap partial win to take now.
Mike wants all of it eventually. This file records what was learned so the investigation does not
have to be repeated.

---

## 1. Where we are today

`explore.html` **is not a viewer**. It is a link farm: a year slider rewrites `<a href>` targets
that hand off to Source Cooperative's hosted build at `https://source-cooperative.github.io/cog-viewer/`
with `url` / `mode` / `rescale` / `colormap` / `nodata` in the query string. Verified against the
live site 2026-09-09 — no iframe, no embed anywhere on wildlandalmanac.org.

Consequence: **every feature we want is in-app state, so all of them require hosting our own build.**
That, not the individual features, is the decision to make. The viewer base URL is one constant near
the top of `explore.html`'s script (`const VIEWER = …`), so the cutover itself is a one-line change.

## 2. What we are forking

[`source-cooperative/cog-viewer`](https://github.com/source-cooperative/cog-viewer), Apache-2.0.

- React 19 + TypeScript + Vite 8, MapLibre GL + deck.gl 9 (`MapboxOverlay`, interleaved).
- COGs are decoded **entirely in the browser** — `@developmentseed/deck.gl-geotiff` /
  `-raster` / `geotiff` (beta 0.8.0), over `@chunkd/source-http` range requests. No tile server.
- ~4,000 lines of `src/`. Vitest unit tests + Playwright e2e, both wired into CI.

Files that matter for the work below:

| File | Why |
|---|---|
| `src/App.tsx` | Map shell; holds the opened `GeoTIFF` object in React state; builds the deck.gl layer |
| `src/state/useCogState.ts` | The entire app state lives in the URL. `parseCogState` / `serializeCogState` — add params here |
| `src/state/types.ts` | `CogState` shape |
| `src/components/ControlsPanel.tsx` | The "Options" panel; new UI goes here (it is already sectioned) |
| `src/render/tile-loader.ts` | `getTileData` — fetches a tile, uploads bands to GPU, **drops the CPU array** |
| `src/render/stats.ts` | Precedent for reading raster values in JS (`source.fetchTile(x,y)`, `tile.array`) |
| `src/cog/metadata.ts` | Shows what the tiff object exposes: `bbox`, `width/height`, `tileWidth/tileHeight`, `crs`, `gkd`, `scales`, `offsets`, `nodata`, `overviews`, `count` |

## 3. What the legacy CECS atlas actually was

`https://cecs.ess.uci.edu/data-atlas/` — decompiled from its bundles 2026-09-09 so we don't have to
guess. **Vue 2 + Leaflet, and every feature we admire is server-backed:**

- Data layers are server-rendered raster tiles from a PHP endpoint on `cecs.ess.uci.edu`
  (`L.tileLayer("…&layerid=" + id)`).
- Click-a-pixel is `fetch("/api/get_geotiff_value.php?lat=…&lon=…&condition=…&layerid[]=…")`
  → JSON → Leaflet popup. Two layer ids are sent when compare mode is on.
- The swipe is the `L.control.sideBySide` plugin between two tile layers, driven by
  `activeYearLeft` / `activeYearRight` and `viewMode: single | compare`.
- Its layer catalog (`label`, `units`, `unitCorrectionFactor`, `minValue`/`maxValue`, `colorRamp`,
  `yearList`, `description`) is a large object baked into `app.*.js`.

**We can do all of it with no server**, because the new viewer already reads the GeoTIFF client-side.
That matters beyond elegance: a PHP box on a UCI host is exactly the dependency the LLC/UCI
separation says not to recreate.

## 4. The four features

### 4a. Click a pixel → value — ~1 day. Do this one first.

Everything needed is already in `App.tsx` state. Mechanism:

1. MapLibre `onClick` gives lng/lat.
2. Reproject to the COG's CRS (EPSG:5070 for WA). Projection machinery is already in the dependency
   tree for `robustEpsgResolver` / `@developmentseed/raster-reproject`; otherwise add `proj4` (~40 KB).
3. `bbox` + `width`/`height` → column/row; `tileWidth`/`tileHeight` → tile x,y.
4. `tiff.fetchTile(x, y)` → index `tile.array` → apply `scales`/`offsets`, check `nodata`.
5. Popup.

~150 lines plus a popup component. Step 3's tile is already in the browser HTTP cache (it was
downloaded to draw the pixel you clicked), so this is usually free.

Two decisions to make deliberately:

- **Report full-resolution values, not the overview pixel on screen.** When zoomed out the display
  comes from an overview; the honest number is the native one. Costs one extra range request.
- **Apply the scaling.** Show "68.2 % tree cover", not "6820". The per-layer conversions already
  exist in `explore.html`'s `THEMES` array (the legacy atlas called this `unitCorrectionFactor`).
  Remember the fire-layer no-data rule: 0, not −9999, and 0 also means genuinely non-burnable.

This feature is generic. **Send it upstream as a PR** rather than carrying it in the fork.

### 4b. Layer / property picker in the viewer — ~1 day, mostly data not code.

The catalog already exists: the `THEMES` array in `explore.html` carries all 21 layers with
`colormap`, `rescale`, `nodata`, units, descriptions, plus the availability rules (Disturbance is
1986–2024; three Fire_LCP bands are static and carry no year). Work:

1. Lift `THEMES` out of `explore.html` into a JSON file **served from this repo**, so the site page
   and the viewer read one catalog and cannot drift.
2. Render a theme-grouped `<select>` at the top of `ControlsPanel`.
3. Picking a layer fires **one** `update()` setting `urls` + `colormap` + `rescale` + `nodata` +
   `mode` together.

Load it via a `catalog=<url>` param rather than baking it in, so the fork stays generic.

### 4c. Year slider in the viewer — ~1–2 days.

Needs one new concept: the viewer today knows only "a URL". Add a template plus a year range, e.g.
`&template=https://…/{layer}/WildlandAlmanac_CA_{layer}_{year}.tif&years=1985-2025`. The slider then
just rewrites `state.urls`.

**The existing code already does the right thing on a URL change** — it re-opens the GeoTIFF but
preserves viewport, colormap and rescale, because `IMAGE_SPECIFIC_RESET` is applied only on
`EmptyState` submit, and `handleBoundsLoad` skips `fitBounds` whenever a zoom is present in the URL.
So a year step keeps the view exactly where it was. That is most of the feature, for free.

The cost is latency: each step is a fresh header read + auto-stats + tile refetch, call it 0.5–2 s
over source.coop. Commit on release rather than on drag (the same `change` vs `input` trick
`explore.html` already uses). The second day is polish:

- Prefetch the adjacent years' headers.
- Skip `computeAutoStats` when the user has pinned the rescale — otherwise every year re-reads
  overviews for a stretch we are about to overwrite.
- Keyboard ◀ ▶ stepping.

### 4d. Year-to-year compare swipe — ~2–4 days. **This is what Mike means by "the year swiper"** (confirmed 2026-09-09).

Two COGs, a draggable vertical handle, left year vs right year. In Leaflet this was a one-line
plugin; in deck.gl there is a single interleaved overlay, so it means:

- Two `COGLayer`s (the multi-URL plumbing partly exists — `urls: p.getAll("url")` and `MultiCOGLayer`
  — but that path composites bands into RGB, it is **not** a spatial split, so it is not reusable here).
- A clip on one of them (`ClipExtension`, or two overlays with clip bounds), updated as the handle moves.
- Handle UI, plus a second year in state (`yearRight`), plus deciding whether the two sides share a
  colormap and stretch (they must, to be comparable — the legacy atlas got this wrong by letting
  each side auto-stretch).

Fiddly edge cases: clip in screen space vs world space under rotation/pitch; both layers must reach
the same zoom level before the wipe reads honestly; the handle must not eat map drag events (the
legacy code has an explicit `"leaflet-sbs-range" !== e.target.className` guard on its click handler
for exactly this).

## 5. Effort and sequencing

Roughly **a week of focused work for 4a–4c; a week and a half with 4d.** Suggested order:
4a (upstream it) → 4b → 4c → 4d. Each is independently shippable.

## 6. Prerequisites — clear these before starting

- **No Node / npm / pnpm on Mike's machine** (checked 2026-09-09). Cannot build or dev-preview a
  React app. Either install Node 22 + corepack/pnpm (10 min), or do every build in GitHub Actions —
  the repo already ships `deploy.yml` for Pages — accepting a slow edit loop.
- **`git` is not on PATH.** The only copy is GitHub Desktop's:
  `C:\Users\Mike\AppData\Local\GitHubDesktop\app-3.6.5\resources\app\git\cmd\git.exe`. No `gh` at all.
  Worth fixing regardless.

## 7. Hosting

Cleanest: serve the fork from a `viewer/` subpath of **this** repo — set Vite's `base` to `/viewer/`,
build in Actions, commit `dist` to `viewer/`. Then it lives on wildlandalmanac.org, same-origin with
`explore.html`, one deploy story, and `explore.html`'s `VIEWER` constant becomes `"viewer/"`.

Alternative: a separate fork repo on its own GitHub Pages. Simpler CI, but a second domain and a
cross-origin boundary that blocks any later idea of embedding the viewer in a page and driving it
from the parent.

## 8. Keeping the fork cheap to maintain

1. Confine WA-specific code to **one added module plus a JSON catalog**; touch as few upstream files
   as possible. Realistically `useCogState.ts` (new params), `types.ts`, `ControlsPanel.tsx` (mount
   points) and `App.tsx` (wiring) get small edits; everything else should be new files.
2. **Upstream anything generic** — 4a certainly, possibly the template/series idea in 4c. Code
   accepted upstream is code we stop maintaining.
3. Pin and watch the three patched beta dependencies (see §9).

## 9. Verdict on the upstream codebase (assessed 2026-09-09)

**Good. Modern, efficient, and genuinely built for extension.** Specifics worth knowing:

- Current stack, no legacy baggage: React 19, Vite 8, deck.gl 9, MapLibre 5, TypeScript strict,
  ESM throughout.
- **All state in the URL** via one `useSyncExternalStore` hook. This is the single best thing about
  it for us: every feature above is "add a param + add a control", and shareable links come free.
- Architecture is properly layered — `cog/` (load, validate, metadata) → `render/` (tiles, stats,
  shader modules, pipeline) → `components/` (UI) → `state/`. Adding a control does not mean touching
  the render path.
- Real performance thinking, not accidental: stable layer ids and a module-scope `getTileData` so
  band/colormap/rescale changes re-**draw** without re-**fetching**; `urlsKey` as a memo dep so
  unrelated param changes don't reload the GeoTIFF; `multiSources` memoized separately so a stats
  update doesn't re-open every COG header; a `FinalizationRegistry` to bound GPU texture leaks.
- The comments explain **why**, including failed attempts (r16float was tried and reverted because
  half-float rounding broke nodata equality). That is a maintained codebase, not a demo.
- Tests: Vitest units on the parsing/stats/metadata logic, Playwright e2e that actually renders a
  COG, both gating PRs.

Honest risks:

- **Three `pnpm` patches against `@developmentseed/*` `0.8.0-beta.2`.** Pre-1.0 dependencies carrying
  local patches are the maintenance risk in this repo. A fork inherits them.
- Upstream ships Sentry; a fork should strip or repoint it.
- `ControlsPanel.tsx` is ~24 KB in one file and is the piece most likely to conflict on merges —
  another reason to mount new UI as separate components.
- CPU-side tile arrays are discarded after GPU upload (`tile-loader.ts`), which is right for memory
  but means 4a re-reads. Fine — it is a cache hit. Do **not** "fix" this by keeping arrays around
  without measuring; that trades a free cache hit for real memory.

## 10. Open items

- Confirm source.coop's CORS allows the extra range requests 4a implies at the rate a click-happy
  user generates (it already serves the tiles, so this is almost certainly fine).
- Decide whether the catalog JSON becomes the single source of truth for `explore.html` too, or
  whether `explore.html` stays self-contained and the JSON is generated from it.
- Categorical layers (`FBFM40`, fuel model) need a class-name lookup in the pixel popup, not a number.
  The legacy atlas had no equivalent; this would be new.
