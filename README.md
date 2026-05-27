# The Wildland Almanac — website

Static site for The Wildland Almanac, an open 30 m Landsat-derived data cube of
California wildland ecosystem properties (water years 1985–2025), hosted on
[Source Cooperative](https://source.coop/wildland-almanac/california).

## Pages
- `index.html` — landing page, theory-of-change figure, six-tile Explore grid
- `inuse.html` — current users (Planscape, Blue Forest, USFS Wildfire Crisis Strategy, CA Wildfire & Forest Resilience Task Force), what the multi-property record reveals at the state scale, and the research footprint
- `data.html` — the 19 layers, six themes, units, license, citation
- `use.html` — access instructions (stream / download / bulk)
- `about.html` — provenance, methods summary, roadmap

## Assets
- `figures/` — embedded figures (CA multi-property time series, CA aboveground biomass 2023 map)
- `.github/ISSUE_TEMPLATE/data_issue_report.md` — GitHub Issues template for data-quality reports
- `.nojekyll` — disables Jekyll processing on GitHub Pages (must be created via "Add file > Create new file" in the GitHub web UI; the drag-uploader strips the leading dot)

Plain static HTML + inline CSS + inline SVG. No build step, no framework.

Contact: mgoulden@uci.edu
