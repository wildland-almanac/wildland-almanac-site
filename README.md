# The Wildland Almanac — website

Static site for The Wildland Almanac, an open 30 m Landsat-derived record of California
wildland ecosystem properties (21 properties, water years 1985–2025), hosted on
[Source Cooperative](https://source.coop/wildland-almanac/california).

Live at **[wildlandalmanac.org](https://wildlandalmanac.org/)**.

Plain static HTML with inline CSS. No build step, no framework, no dependencies.

## Pages

| File | What it is |
|---|---|
| `index.html` | Landing page: scope, the 21 properties, a rendered flame-length map with a year slider, and four cards |
| `explore.html` | **Every layer, every year.** All 28 layers deep-linked into the Source Cooperative COG viewer, driven by one year slider |
| `benchmarking.html` | Hub for the benchmarking results — three evidence axes, results at a glance, strengths and shortfalls |
| `bench-*.html` | Seven property pages: AGB, cover, disturbance, dieoff, water, fire flame length, fire burn probability |
| `data.html` | The 21 layers by theme, with units, scaling conventions, caveats, license and citation |
| `use.html` | Access instructions — stream, download one file, bulk sync — with ArcGIS / QGIS / Python / R examples |
| `about.html` | How the data are produced, project history, credits, contact |

## Assets and tooling

- `img/fl_2025_ca.png` — the homepage map, rendered from the published `Fire_ELMFire_FL` 2025 COG
  with `gdalwarp` + `gdaldem color-relief`. **Note the fill value: the three ELMFIRE layers store
  masked ground as `0`, not `−9999`** — use `-srcnodata 0` or the ocean comes through as data.
- `img/bench/*.png` — the seven benchmarking figures, extracted from
  `WildlandAlmanac_CA_QualityBenchmarks.docx`.
- `_tools/build_benchmarking.ps1` — generates `benchmarking.html` and all seven `bench-*.html`.
  **The benchmarking numbers live in this script, not in the generated HTML.** Edit here and re-run;
  do not hand-edit the output.
  ```powershell
  powershell -NoProfile -File _tools\build_benchmarking.ps1
  ```
- `.github/ISSUE_TEMPLATE/data_issue_report.md` — issue template for data-quality reports.
- `.nojekyll` — disables Jekyll processing. Must be created via *Add file → Create new file* in the
  GitHub web UI; the drag-uploader strips the leading dot.
- `CNAME` — the custom domain.

## Sources of truth

The site summarises; these are authoritative and live on Source Cooperative:

- **`WildlandAlmanac_CA_Documentation.pdf`** — layer specifications, units, scaling, mask, grid.
- **`WildlandAlmanac_CA_QualityBenchmarks.pdf`** — the benchmarking results. When it is revised,
  replace the figures in `img/bench/` and update the content block in the generator.
- **`README.md`** at the dataset root — what a data user reads first. Kept in step with `data.html`;
  when the layer roster or a convention changes, both need editing.

## Deploying

GitHub Pages builds from `main`. Commit and push; the site updates in about a minute.

## The COG viewer

`explore.html` deep-links to the [Source Cooperative COG viewer](https://github.com/source-cooperative/cog-viewer)
(Apache-2.0, static, browser-only), passing `rescale`, `colormap` and a per-layer `nodata`. The base
URL is a single constant near the top of the page script, so serving a fork from this repo instead is
a one-line change.

`explore.html` is a link farm, not a viewer — it hands off to Source's hosted build, so anything
in-app (year slider, layer picker, click-a-pixel readout, year-to-year compare swipe) needs us to
host our own fork. That was investigated on 2026-09-09 and **tabled**; findings, effort estimates,
prerequisites and a verdict on the upstream codebase are in
[`VIEWER_ROADMAP.md`](VIEWER_ROADMAP.md).

Contact: mgoulden@uci.edu
