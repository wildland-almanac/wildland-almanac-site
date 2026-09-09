<#
  build_benchmarking.ps1 — generate the benchmarking pages from the distilled
  content of WildlandAlmanac_CA_QualityBenchmarks.pdf (2026-09-07).

  The PDF is the AUTHORITY. This script is the only place the numbers live in
  web form; edit here and re-run rather than hand-editing the generated HTML.

      pwsh -NoProfile -File _tools\build_benchmarking.ps1

  Writes: benchmarking.html + bench-<slug>.html x7 into the repo root.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

# ---------------------------------------------------------------- shared CSS
# Matches the existing site palette (utilitarian Source/GitHub/USGS register).
$CSS = @'
  :root{
    --ink:#1b1b1b; --ink-soft:#3a3a3a; --muted:#6a6a6a;
    --line:#d8d6d0; --line-strong:#bdbab2;
    --paper:#fbfaf7; --panel:#ffffff;
    --accent:#2f5d3a; --accent-soft:#eef2ec;
    --link:#1a4f78; --code-bg:#f4f2ec;
    --good:#2f6b45; --good-bg:#e8f0e9;
    --warn:#8a6212; --warn-bg:#f5efdd;
    --maxw:980px;
    --mono: ui-monospace,"SFMono-Regular","Menlo","Consolas",monospace;
    --serif: Georgia,"Iowan Old Style","Times New Roman",serif;
    --sans: -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,sans-serif;
  }
  *{box-sizing:border-box}
  html{-webkit-text-size-adjust:100%}
  body{margin:0;background:var(--paper);color:var(--ink);font-family:var(--sans);font-size:16px;line-height:1.55}
  a{color:var(--link);text-decoration:none} a:hover{text-decoration:underline}
  .wrap{max-width:var(--maxw);margin:0 auto;padding:0 24px}
  .topbar{border-bottom:1px solid var(--line);background:var(--panel)}
  .topbar .wrap{display:flex;align-items:center;justify-content:space-between;height:58px}
  .brandmark{font-family:var(--serif);font-size:18px;color:var(--ink)}
  .brandmark a{color:inherit}
  .brandmark .the{color:var(--muted);font-style:italic;margin-right:4px}
  .nav a{color:var(--ink-soft);font-size:14px;margin-left:22px}
  .nav a:hover{color:var(--accent)} .nav a.here{color:var(--accent);font-weight:600}
  @media(max-width:640px){.nav a{margin-left:14px;font-size:13px}.topbar .wrap{height:52px}}
  .crumb{font-size:13px;color:var(--muted);margin:14px 0 0}
  .pagehead{border-bottom:1px solid var(--line);background:linear-gradient(180deg,#fff,var(--paper));padding:30px 0 26px;margin-top:12px}
  h1{font-family:var(--serif);font-weight:600;font-size:34px;line-height:1.12;margin:0 0 10px;letter-spacing:-.2px}
  .lede{font-size:17px;color:var(--ink-soft);margin:0;max-width:74ch}
  .specs{display:flex;flex-wrap:wrap;gap:0;border:1px solid var(--line-strong);border-radius:4px;overflow:hidden;
    background:var(--panel);font-family:var(--mono);font-size:13px;width:max-content;max-width:100%;margin-top:18px}
  .specs span{padding:7px 14px;border-right:1px solid var(--line);color:var(--ink-soft);white-space:nowrap}
  .specs span:last-child{border-right:none} .specs b{color:var(--ink);font-weight:600}
  @media(max-width:640px){h1{font-size:27px}.specs{width:100%}.specs span{flex:1 1 auto;text-align:center}}
  section.block{padding:26px 0 6px}
  h2{font-family:var(--serif);font-size:22px;font-weight:600;margin:0 0 6px;letter-spacing:-.15px}
  h3{font-size:16px;font-weight:600;margin:24px 0 6px}
  p{margin:0 0 14px;max-width:76ch;color:var(--ink-soft)}
  p strong,li strong{color:var(--ink)}
  .sec-lede{margin:0 0 16px;max-width:76ch;color:var(--ink-soft)}
  code{font-family:var(--mono);font-size:.87em;background:var(--code-bg);padding:1px 5px;border-radius:3px;color:var(--ink-soft)}
  .tw{overflow-x:auto;margin:16px 0 22px}
  table{border-collapse:collapse;width:100%;font-size:14.5px;line-height:1.5}
  th{text-align:left;font-family:var(--mono);font-size:11px;text-transform:uppercase;letter-spacing:.07em;
    color:var(--muted);font-weight:600;padding:0 14px 8px 0;border-bottom:1px solid var(--line-strong);vertical-align:bottom}
  td{padding:13px 14px 13px 0;border-bottom:1px solid var(--line);color:var(--ink-soft);vertical-align:top}
  tr:last-child td{border-bottom:none}
  td.axis{color:var(--ink);font-weight:600;white-space:nowrap;width:150px}
  .pill{display:inline-block;font-family:var(--mono);font-size:10.5px;text-transform:uppercase;letter-spacing:.06em;
    padding:2px 7px;border-radius:3px;font-weight:600;white-space:nowrap}
  .pill.hi{background:var(--good-bg);color:var(--good)} .pill.lo{background:var(--warn-bg);color:var(--warn)}
  .note{margin:16px 0;padding:14px 18px;max-width:80ch;background:var(--accent-soft);border-radius:5px;
    font-size:14.5px;color:var(--ink-soft);line-height:1.55}
  .note.warn{background:var(--warn-bg)}
  .note b{color:var(--ink)}
  .axes{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:18px 0 8px}
  @media(max-width:760px){.axes{grid-template-columns:1fr}}
  .axcard{border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:5px;background:var(--panel);padding:16px 18px}
  .axcard h3{margin:0 0 6px;font-size:15.5px;color:var(--ink)}
  .axcard p{margin:0;font-size:14px;line-height:1.5}
  .cards{display:grid;grid-template-columns:repeat(2,1fr);gap:14px;margin:18px 0}
  @media(max-width:640px){.cards{grid-template-columns:1fr}}
  .card-link{display:block;border:1px solid var(--line);border-radius:5px;background:var(--panel);padding:16px 18px;color:inherit}
  .card-link:hover{border-color:var(--accent);text-decoration:none}
  .card-link .k{font-family:var(--mono);font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.09em}
  .card-link h3{font-size:16.5px;margin:5px 0 5px;color:var(--ink)}
  .card-link p{margin:0;font-size:14px}
  .card-link .verdict{margin-top:9px;display:flex;gap:6px;flex-wrap:wrap}
  .panels{font-size:14.5px;color:var(--ink-soft);margin:0 0 8px}
  .panels b{color:var(--ink);font-family:var(--mono);font-size:12.5px}
  figure.bench{margin:0 0 22px;padding:0}
  figure.bench img{display:block;width:100%;height:auto;border:1px solid var(--line-strong);
    border-radius:5px;background:var(--panel)}
  figure.bench figcaption{font-size:13px;color:var(--muted);margin-top:9px;line-height:1.5;max-width:80ch}
  figure.bench figcaption a{color:var(--link)}
  ul{margin:0 0 14px;padding-left:20px} li{margin-bottom:7px;color:var(--ink-soft);max-width:76ch}
  footer{border-top:1px solid var(--line);background:var(--panel);padding:26px 0 34px;margin-top:34px;font-size:13.5px;color:var(--muted)}
  footer p{max-width:80ch;margin:0 0 6px;font-size:13.5px}
'@

function Head([string]$title,[string]$here){
@"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title - The Wildland Almanac</title>
<style>
$CSS
</style>
</head>
<body>
<header class="topbar">
  <div class="wrap">
    <div class="brandmark"><a href="index.html"><span class="the">The</span>Wildland Almanac</a></div>
    <nav class="nav">
      <a href="data.html">The Data</a>
      <a href="explore.html">Explore</a>
      <a href="benchmarking.html"$(if($here -eq 'bench'){' class="here"'})>Benchmarking</a>
      <a href="use.html">Use It</a>
      <a href="about.html">About</a>
      <a href="https://source.coop/wildland-almanac">Source&nbsp;&#8599;</a>
    </nav>
  </div>
</header>
"@
}

$FOOT = @'
<footer>
  <div class="wrap">
    <p><b>Source.</b> These pages are generated from <i>WildlandAlmanac_CA_QualityBenchmarks.pdf</i>
    (v2026.1, 7 September 2026), which is the authoritative document and contains the figures each
    panel reference points at. <a href="https://data.source.coop/wildland-almanac/california/WildlandAlmanac_CA_QualityBenchmarks.pdf">Download the full PDF &#8599;</a></p>
    <p>Released under CC BY 4.0. Findings are stated as measured, including where the Almanac is
    weaker than an alternative.</p>
  </div>
</footer>
</body>
</html>
'@

# ------------------------------------------------------------------- content
# Each property: slug, name, oneline, panels (a..g), 3 axes x (strength, weakness),
# synthesis high / low, specifics.
$P = @(
 @{ slug='agb'; name='Aboveground biomass'; layer='Carbon_AGB'
    one='Tracks FIA to about 200 Mg/ha then saturates; agrees closely with GEDI lidar; misses diffuse mortality.'
    hi='Magnitude of AGB; rate of growth in young stands; abrupt disturbance loss'
    lo='Diffuse mortality and closed-canopy growth'
    panels=@(
      'a  WA biomass against 13,395 FIA field plots, one 30 m pixel per plot, 2013-2023. WA tracks FIA to ~200 Mg/ha, then saturates.'
      'b  WA 2020 against GEDI lidar on GEDI''s 1 km grid. Close agreement (slope 0.98, R&sup2; 0.83), so WA''s biomass level is not an artefact of averaging.'
      'c  Yearly biomass gain in stands under 30 years old, WA against repeat-visit FIA plots. Similar spread and shape; median WA about 40% low.'
      'd  Biomass remaining after disturbance, by cause. WA matches FIA after fire, but misses most loss from insects, disease and drought.'
      'e  Biomass gain against stand age. The two agree for the first 30 years; after that WA is low by up to 80%.'
      'f  Average WA biomass 1985-2025 for forest never disturbed. Smooth and steady, with no jumps where the Landsat satellites changed over.'
      'g  The same never-disturbed forest split by 1985 starting biomass. Classes separate sensibly, though rates likely underestimate true growth due to saturation.')
    ext_s='WA AGB reproduces the FIA pattern (R&sup2; 0.90 at 50 km) <b>and</b> holds at native 30 m: R&sup2; 0.47 against fuzzed FIA, near the ceiling that FIA fuzzing and plot noise allow [a]. Accumulation rates in young (&lt;30 yr) stands match FIA in magnitude and distribution [c, e]. Disturbance loss magnitudes reproduce FIA repeat observations [d].'
    ext_w='WA significantly underestimates AGB loss from diffuse mortality [d]. It underestimates growth rate in mid to older stands from about 40 yr [e], and underestimates AGB in stands above ~200 Mg/ha [a]. These last two are consistent: saturation likely leads to underestimated increment in larger or older forests, with implications for regional accumulation accounting.'
    int_s='The never-disturbed cohort is temporally stable with steady monotonic growth, and shows no discontinuities or seams at Landsat sensor changeovers [f]. Trends within it follow trajectories consistent with forestry and ecosystem dynamics, rolling off with age and AGB [g].'
    int_w='Some of that smoothness and roll-off may itself reflect the inability of WA - and other optical AGB datasets - to detect modest change in stands that are already large, whether from optical saturation or from allometric decoupling between AGB and canopy height.'
    crx_s='Good agreement with GEDI L4B at 1 km: slope 0.98, R&sup2; 0.83. Agreement is not an averaging artefact, and GEDI is a lidar peer of independent lineage [b].'
    crx_w='That very similarity implies much of the saturation may have an <b>allometric</b> source rather than an optical one, since GEDI should be immune to optical saturation.'
    spec='WA = <code>Carbon_AGB</code>. References: FIA field plots (FIADB California, 2024 release; measured 2013-2023); GEDI L4B v2.1 gridded biomass at 1 km, covering 2019-04 to 2021-08, compared against WA 2020.' },

 @{ slug='cover'; name='Cover and structure'; layer='Veg_TreeFrac'
    one='Tree cover matches NLCD closely and tracks burn severity; independent evidence for change accuracy is the weak point.'
    hi='Tree-cover level and pattern; loss scales with severity; precise in time'
    lo='No independent change accuracy; non-tree fractions and diffuse change'
    panels=@(
      'a  WA tree cover against 5,776 FIA field plots at 60 m. Modest agreement (R&sup2; 0.32); field crews measure cover differently, so this is the hardest test on the page.'
      'b  WA against the national NLCD tree-canopy product at 240 m. Close agreement (R&sup2; 0.94), though WA reads about 20% higher.'
      'c  All four cover fractions - tree, shrub, herb, bare - against RCMAP and RAP. WA divides the ground much as they do.'
      'd  Cover loss against independent MTBS fire severity. Loss rises 4.5-fold from lightly to severely burned.'
      'e  Average WA tree cover 1985-2025 for forest never disturbed. Steady, with no jumps at the Landsat changeovers.'
      'f  The same never-disturbed forest split by 1985 cover class. Classes stay separated and move sensibly.')
    ext_s='WA tree cover matches FIA field plots (R&sup2; 0.32) [a]. Tree-cover loss scales with independent MTBS burn severity, 4.5x from low to high [d] - a non-circular cover test, though both rely on Landsat.'
    ext_w='Independent field evidence for tree-cover <i>change</i> accuracy is weak (FIA remeasurement R&sup2; 0.26, mostly loss-side). We have temporal precision [e, f] but cannot prove change accuracy from field observations. Diffuse change below the noise floor is invisible.'
    int_s='The never-disturbed cohort is temporally stable with steady monotonic growth and no large discontinuities at Landsat changeovers [e]. Trends roll off sensibly with increasing cover [f].'
    int_w='The four cover types are forced to sum to 100%, so they are not independent of one another.'
    crx_s='WA tree cover matches NLCD-TCC (R&sup2; 0.94) [b], and reproduces the whole tree/shrub/herb/bare partition against RCMAP and RAP [c].'
    crx_w='<b>Circular evidence:</b> all gridded cover is Landsat-derived. USFS TCC trains WA tree; RAP trains shrub/herb/bare; only RCMAP is independent for all four. The non-tree fractions are noisier, shrub especially [c].'
    spec='WA = <code>Veg_TreeFrac</code>. References: FIA field plots (FIADB California, 2024 release); NLCD tree canopy cover 2019 (v2023-5); RCMAP 2020; RAP v3 2020; MTBS thematic severity 1984-2024.' },

 @{ slug='disturbance'; name='Disturbance'; layer='Disturbance_TreeFrac / Disturbance_AGB'
    one='Finds and dates fire very well - 92% of high-severity area, 92% within a year - but under-registers diffuse and partial disturbance.'
    hi='Fire location, timing and severity'
    lo='Non-fire-agent magnitude and small-event detection'
    panels=@(
      'a  Biomass remaining after disturbance, WA against FIA field plots, by cause. Good agreement after fire; most insect, disease and drought loss is missed.'
      'b  WA biomass loss against independent MTBS fire severity. Loss climbs steeply, from 7 Mg/ha in the lightest class to 92 in the heaviest.'
      'c  Where WA and Hansen both see forest loss, pooled to 1 km. WA finds 66% of Hansen''s loss, and 96% of shared detections agree on the year within one.'
      'd  The same against MTBS fire. WA finds 92% of high-severity fire and 81% of moderate, and dates 92% of it within one year.')
    ext_s='FIA field: WA tracks how much biomass each agent removes, with fire capture 0.66 [a]. Loss rises monotonically with independent MTBS severity, 7 to 92 Mg/ha [b]. Severe fire drives post-fire AGB toward zero (10% below 25 Mg/ha).'
    ext_w='Non-fire <b>magnitude</b> is soft: mortality capture 0.15, harvest 0.28 - diffuse and partial disturbance is under-registered [a]. The detection floor misses small and low-severity events.'
    int_s='Closure holds: large AGB drops coincide with the disturbance flag, and only 2% of pixel-years are big drops with no flag. WA correctly identifies fire as the dominant agent.'
    int_w='That 2% is diffuse mortality the abrupt-change detector misses. The layer targets abrupt loss, not gradual decline - by design, but it bounds what it can be used for.'
    crx_s='At 1 km, WA maps and dates fire with no bias (median on the 1:1): high-severity recall 92%, Jaccard 0.58, 92% within &plusmn;1 yr against MTBS [d]. Hansen agrees on stand replacement (Jaccard 0.53, 96% within &plusmn;1 yr) [c].'
    crx_w='MTBS and Hansen share Landsat lineage with WA, so this is consistency rather than proof - though they are independently produced, which makes agreement on where and when meaningful. Per-cell fraction density scatters (R&sup2; 0.55) where WA biomass and MTBS dNBR draw intensity differently.'
    spec='WA = <code>Disturbance</code>, 1986-2024. References: Hansen/UMD Global Forest Change v1.12 (annual loss 2001-2024); MTBS thematic severity 1984-2024; FIA repeat-visit plots (FIADB California, 2024 release).' },

 @{ slug='dieoff'; name='Drought dieoff'; layer='Vulner_TreeDieoff_*'
    one='Locates dieoff through a super-additive height x deficit interaction, and leads aerial survey by about a year - but it is a screening layer, not a per-pixel count.'
    hi='Height x multi-year deficit interaction locates dieoff'
    lo='Per-pixel severity and absolute totals'
    panels=@(
      'a  Canopy water loss split by canopy height and by drought. Where both are extreme the loss is 4.4x what the two effects added separately would predict.'
      'b  The same corner measured by aerial-survey mortality: 3.7 trees per acre where neither is extreme against 27 where both are, a 7.7-fold difference. The canopy axis reverses in this currency.'
      'c  The two dieoff layers side by side. One tracks year-to-year change, the other is a static susceptibility map; they do different jobs.'
      'd  Predicted vulnerability against observed canopy water loss, binned to the scale a manager would use: a clean 6.6-fold dose-response.'
      'e  Can the map anticipate dieoff? The susceptibility layer captures more of the eventual mortality than exposure to drought alone.'
      'f  WA canopy-height loss against aerial-survey mortality over time. WA leads the survey by about a year (r 0.78), and the lead survives detrending.')
    ext_s='Observed canopy height <b>leads</b> ADS drought-and-beetle mortality by one year (r 0.78), and the lead survives first-differencing [f]. Independently, canopy water loss rises with the same hazard, both in the corner test and as a dose-response [a, d].'
    ext_w='Pixel R&sup2; is small (~0.02). This is a drought-conditioned screening layer, not a per-pixel mortality counter - report capture and dose-response, not per-pixel severity.'
    int_s='The killer corner is <b>super-additive</b>: dieoff needs both tall canopy and severe deficit, and is monotone in both axes (4.4x in canopy water content) [a]. Deficit is the invariant driver - the canopy axis reverses currency on ADS stems [b].'
    int_w='Scope is a single drought epicentre in a single state (2012-16 southern Sierra). Generalisation to CONUS and to other droughts is future work.'
    crx_s='Clean decision-scale dose-response, 6.6x top-to-bottom decile [d]. The static susceptibility layer beats plain drought exposure prospectively, 1.56x against 0.36x [e]. The dynamic and static layers do genuinely distinct jobs [c].'
    crx_w='Absolute severity and totals are unresolved - the layer sets the odds, not per-pixel counts. ADS is itself a lower bound on scattered mortality.'
    spec='Both references are <b>independent of WA</b>: USFS aerial detection survey mortality (CA BIOS ds2783, survey years 2015-2017 summed) and Brodrick/Asner canopy water content, 2014-2017.' },

 @{ slug='water'; name='Water'; layer='WaterFlux_*'
    one='The strongest external test in the dataset: runoff matches 122 gauged basins in both space and time, and AET holds steady beneath a five-fold runoff swing.'
    hi='Runoff in space and time; AET magnitude; long-term precision and stability'
    lo='Water response to disturbance; possible saturation at high AET'
    panels=@(
      'a  WA runoff against 122 gauged basins, basin by basin. Close match across the state (R&sup2; 0.87, slope 1.01).'
      'b  The same with each basin''s own average removed, so only wet-year against dry-year differences remain. WA still tracks the gauges (R&sup2; 0.83).'
      'c  WA evapotranspiration against what the water balance requires - precipitation minus streamflow and storage change. Right level and slope; scatter is wide because AET itself varies little.'
      'd  WA runoff against the USFS Forests-to-Faucets water-yield product. Excellent agreement (slope 1.02, R&sup2; 0.91).'
      'e  Change in evapotranspiration after disturbance at paired eddy-covariance flux towers, observed against WA. Direction right, about two-thirds of the size.'
      'f  Year by year across 46 basins: observed and WA runoff (solid) and two estimates of AET (dashed). Runoff tracks almost exactly, while AET stays flat beneath a five-fold swing in runoff.')
    ext_s='Runoff matches gauges in space (R&sup2; 0.87, slope 1.01) [a] and in time (interannual deviation R&sup2; 0.83) [b], and reproduces the observed wet/dry sequence year by year (r 0.99, bias -29 mm) [f]. WA AET is consistent with independent water-balance AET from precipitation minus gauged runoff [c]. Across disturbed flux-tower pairs, WA AET tracks the measured change [e]: 46 contrast-years, 8 paired stands, bias 7 mm, RMSE 90 mm, NDVI elasticity 0.40 against 0.41 observed.'
    ext_w='The disturbance test rests on a sparse and noisy dataset [e], and WA may underestimate the AET change with disturbance (gain 0.69). No basin-scale disturbance-response test exists. Panel c hints at saturation at higher AET and possible underestimation in the wettest basins. Fine spatial detail and AET interannual amplitude remain buffered. These analyses are butting up against the limits of what benchmarking data exist.'
    int_s='WA AET holds steady beneath a runoff signal that swings five-fold [f] - interannual variance in runoff is driven mainly by precipitation, not AET. The never-disturbed cohort agrees: AET buffered to about 0.05x the precipitation amplitude, seam-free over 40 years.'
    int_w='The never-disturbed cohort shows interannual variability with drought that is likely real, which precludes the full stability analysis done for the other properties.'
    crx_s='Excellent agreement between WA runoff and USFS Forests-to-Faucets: slope 1.02, R&sup2; 0.91 [d].'
    crx_w='Both axes of that comparison are strongly driven by precipitation, traceable to a common lineage, and F2F is coarse-resolution. The runoff comparisons generally (a, b, d, and runoff in f) are weaker evidence than they superficially appear for the same reason; the <b>AET</b> comparisons (c, e, AET in f) subtract that effect out and are the stronger evaluation.'
    spec='WA runoff is precipitation minus WA AET. References: 122 gauged basins (USGS NWIS and CDEC full natural flow); USFS Forests-to-Faucets 2.0 water yield; AmeriFlux eddy-covariance towers. A variety of alternative water-balance products were also tested; most compared poorly against <i>each other</i>, and it was difficult to identify strong datasets for intercomparison.' },

 @{ slug='fire-flamelength'; name='Fire: flame length'; layer='Fire_ELMFire_FL'
    one='Beats a published commercial model at predicting where severe fire later occurred, in both years where a matched comparison is possible.'
    hi='Identifies pixels at elevated risk of high-severity fire, and tracks them precisely for four decades'
    lo='Weaker within shrub and timber-understory fuel classes'
    panels=@(
      'a  WA flame length against Pyrologix, a published commercial model, for the same places. Same pattern (R&sup2; 0.62); WA reads lower because it uses a different crown-fire model.'
      'b  How severely fires actually burned, grouped by WA''s predicted flame length. Severe area climbs steeply from the lowest tenth to the highest.'
      'c  Each year 1986-2024: the share of severely burned area falling in the top 20% of predicted flame length. Above chance (0.20) in all 39 years, and always better than predicting from burned area alone.'
      'd  WA against Pyrologix on the identical test, for the two years Pyrologix covers. WA scores higher in both.'
      'e  Average WA flame length 1995-2024 for forest never disturbed. Gradual, ecologically plausible fuel build-up with no jumps at the Landsat changeovers.')
    ext_s='A clear relationship between predicted flame length and subsequent high-severity fire, with cap20 of 0.61 - that is, 61% of severe fire occurs in pixels that were in the top 20% of predicted flame length the previous year [c]. Skill is consistent across the whole 40-year record: cap20 averages <b>0.605</b>, exceeding random by more than 200%, with little or no degradation back to the 1980s.'
    ext_w='Not all fuel classes behave alike. GR, GS and TL match or beat the pooled 0.61 within class, but SH and TU fall to 0.28-0.42. The layers use weighted weather reflecting local climatology and do not consider local ignition probability; they are not predictions of severity for any specific fire, where weather variation is a strong driver.'
    int_s='Undisturbed-cohort flame length rises 3.2% across the record, 1.93 to 1.99 m (+0.0024 m/yr), reflecting gradual and ecologically plausible fuel build-up [e]. Landsat transitions are clean, with no step changes or inflections.'
    int_w='&mdash;'
    crx_s='Good agreement with contemporaneous Pyrologix flame length (R&sup2; 0.62) [a]. <b>On the matched predictive test WA scores higher in both available years: 0.645 against 0.575 (2021) and 0.789 against 0.677 (2022)</b> [c, d].'
    crx_w='The magnitude difference against Pyrologix likely reflects contrasting crown-fire models - WA uses ELMFIRE''s Cruz algorithm, which yields lower flame lengths than the Scott parameterisation Pyrologix uses. So the level is not directly comparable even though the pattern and the skill are.'
    spec='WA flame length is a <b>conditional climatology</b> - what would burn if a fire arrived under typical local weather, not a forecast for any particular fire. References: Pyrologix (2021-2022) and MTBS thematic severity 1984-2024.' },

 @{ slug='fire-burnprobability'; name='Fire: burn probability'; layer='Fire_ELMFire_BurnProbabilityRelative'
    one='Ranks where fire occurs well above chance across four decades - but an annually-updated FSim product beats it on every overlapping year.'
    hi='Maps burn probability across the landscape and tracks elevated risk for four decades'
    lo='Moran and Pyrologix predict subsequent burning better; WA is not calibrated to absolute probability'
    panels=@(
      'a  WA against the published Moran burn probability, cell by cell across California.'
      'b  Year by year against Moran and Pyrologix on the same test, so the three are scored identically.'
      'c  Forty years: the share of burned area falling in the top 20% of predicted burn probability. Above chance (0.20) in nearly every year.'
      'd  What that score means - the cumulative capture curve, showing how much fire is caught as more of the landscape is included.'
      'e  Two never-disturbed cohorts from 1995: all such pixels and only those with no fire within 10 km. The isolated set rises as fuel accumulates; the other falls because neighbouring fire removes fuel.')
    ext_s='A clear relationship between predicted burn probability and subsequent fire, with cap20 of 0.52 [d]. BP ranks where fire occurs well above chance in the recent, fully independent years (0.582 across five, all above the 0.20 floor), and holds across the 40-year record with only modest degradation back to the 1980s [c] - likely driven by consistently lower burn occurrence, since fewer fires make prediction noisier.'
    ext_w='&mdash;'
    int_s='Undisturbed-cohort BP rises systematically for pixels with no fire within a 10 km buffer, reflecting fuel build-up [e]. Landsat transitions are clean. Pixels <i>with</i> nearby fire show no such rise, then an abrupt decrease coincident with the large statewide increase in burning - BP is tracking neighbourhood fire, as it should.'
    int_w='&mdash;'
    crx_s='General agreement with Moran and Pyrologix on relative BP within identical cells [a]; the two maps agree cell by cell (Spearman 0.61 against Moran). Scores against subsequent burn occurrence are broadly consistent with both in most years [b].'
    crx_w='<b>Moran''s annually-updated FSim BP beats WA on all four overlapping years</b>, with an especially large gap in the high-fire year 2020 (-0.100). Panel a is rank-only: WA is not calibrated to absolute BP the way Moran and Pyrologix are, so comparisons of level or slope are not possible.'
    spec='WA burn probability is a <b>conditional climatology, not a forecast</b>. References: Moran et al. 2025 annual burn probability (OSF z6gnt, 2020-2023); Pyrologix; observed burned area from MTBS and FRAP perimeters.' }
)

# ------------------------------------------------------------ property pages
foreach($x in $P){
  $panelHtml = ($x.panels | ForEach-Object {
      $lbl = $_.Substring(0,1); $txt = $_.Substring(2).Trim()
      "      <p class=""panels""><b>$lbl</b> &nbsp;$txt</p>" }) -join "`n"

  $body = @"
$(Head $x.name 'bench')
<div class="wrap"><p class="crumb"><a href="index.html">Home</a> / <a href="benchmarking.html">Benchmarking</a> / $($x.name)</p></div>

<div class="pagehead">
  <div class="wrap">
    <h1>$($x.name)</h1>
    <p class="lede">$($x.one)</p>
    <div class="specs">
      <span><b>Layer</b>&nbsp;$($x.layer)</span>
      <span><b>3</b>&nbsp;evidence axes</span>
      <span>v2026.1</span>
    </div>
  </div>
</div>

<section class="block">
  <div class="wrap">
    <h2>What was compared</h2>
    <figure class="bench">
      <img src="img/bench/$($x.slug).png" alt="$($x.name) benchmarking figure: multi-panel comparison of Wildland Almanac against reference data.">
      <figcaption>Benchmarking panels for $($x.name.ToLower()), from
      <a href="https://data.source.coop/wildland-almanac/california/WildlandAlmanac_CA_QualityBenchmarks.pdf">WildlandAlmanac_CA_QualityBenchmarks.pdf</a>
      (v2026.1). Panel letters below correspond to the panels above.</figcaption>
    </figure>
$panelHtml
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>Evidence</h2>
    <p class="sec-lede">Strengths and weaknesses on each axis, as measured. Weaknesses are stated at
    the same level of detail as strengths.</p>
    <div class="tw">
      <table>
        <thead><tr><th>Axis</th><th>Strengths</th><th>Weaknesses</th></tr></thead>
        <tbody>
          <tr><td class="axis">External skill</td><td>$($x.ext_s)</td><td>$($x.ext_w)</td></tr>
          <tr><td class="axis">Internal coherence</td><td>$($x.int_s)</td><td>$($x.int_w)</td></tr>
          <tr><td class="axis">Cross-dataset consistency</td><td>$($x.crx_s)</td><td>$($x.crx_w)</td></tr>
        </tbody>
      </table>
    </div>
    <div class="note">
      <b>Synthesis.</b><br>
      <span class="pill hi">High confidence</span> &nbsp;$($x.hi)<br><br>
      <span class="pill lo">Lower confidence</span> &nbsp;$($x.lo)
    </div>
    <h3>Specifics</h3>
    <p>$($x.spec)</p>
  </div>
</section>
$FOOT
"@
  $out = Join-Path $root "bench-$($x.slug).html"
  Set-Content -Path $out -Value $body -Encoding utf8
  Write-Host "  wrote bench-$($x.slug).html"
}

# ------------------------------------------------------------------ hub page
$cards = ($P | ForEach-Object {
@"
      <a class="card-link" href="bench-$($_.slug).html">
        <span class="k">$($_.layer)</span>
        <h3>$($_.name)</h3>
        <p>$($_.one)</p>
        <div class="verdict"><span class="pill hi">High</span> <span class="pill lo">Lower</span></div>
      </a>
"@ }) -join "`n"

$summaryRows = ($P | ForEach-Object {
"          <tr><td class=""axis""><a href=""bench-$($_.slug).html"">$($_.name)</a></td><td>$($_.hi)</td><td>$($_.lo)</td></tr>" }) -join "`n"

$hub = @"
$(Head 'Benchmarking' 'bench')
<div class="wrap"><p class="crumb"><a href="index.html">Home</a> / Benchmarking</p></div>

<div class="pagehead">
  <div class="wrap">
    <h1>Benchmarking</h1>
    <p class="lede">How well each layer performs, measured on three axes - and stated plainly,
    including where the Almanac is weaker than the alternatives.</p>
    <div class="specs">
      <span><b>7</b>&nbsp;property areas</span>
      <span><b>3</b>&nbsp;evidence axes</span>
      <span><b>41</b>&nbsp;years tested</span>
      <span>v2026.1</span>
    </div>
  </div>
</div>

<section class="block">
  <div class="wrap">
    <h2>The niche this is built for</h2>
    <p>There are already many single-epoch geospatial datasets, usually covering one or a few recent
    years and one or a few properties - biomass (GEDI), water (Forests-to-Faucets), disturbance
    (Hansen), fuels and wildfire (LANDFIRE), vegetation type (RAP). Many offer high spatial accuracy
    and rest on foundational work that gave the Almanac excellent starting points.</p>
    <p><strong>Improving on their spatial accuracy is not the aim.</strong> The field already knows a
    great deal about mapping near-current biomass, water balance, fuel and wildfire, and highly
    capable groups are working on it. The aim is to extend those records across the full Landsat
    archive with enough <strong>temporal precision</strong> to say reliably how conditions changed
    over four decades at 30 m, from single pixels to CONUS, and to difference years to show where and
    when. Confirming that recent-year patterns agree with established products is a necessary
    baseline for that - but it is not sufficient, and it is not the interesting part.</p>
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>Three axes</h2>
    <div class="axes">
      <div class="axcard">
        <h3>External skill</h3>
        <p>Spatial and temporal accuracy against real observations - river gauges, fire perimeters,
        field plots. Direct comparison with high-priority real-world conditions.</p>
      </div>
      <div class="axcard">
        <h3>Internal coherence</h3>
        <p>Stability within a constant cohort of never-disturbed pixels. Ensures multi-year
        observations see real change rather than dataset artefacts, noise or drift.</p>
      </div>
      <div class="axcard">
        <h3>Cross-dataset consistency</h3>
        <p>Agreement with established datasets such as LANDFIRE, GEDI and RCMAP. A minimum quality
        threshold - these products are widely used and accepted.</p>
      </div>
    </div>
    <div class="note">
      <b>The first two axes are the ones that matter most here, and the ones most often skipped.</b>
      Both speak directly to temporal precision. The never-disturbed-cohort test asks a question few
      products ask of themselves: across 41 years and four Landsat sensor changeovers, does an
      undisturbed pixel stay put? A seam at a satellite transition is invisible in any single-epoch
      comparison, and fatal to measuring change. Together the three axes establish whether the Almanac
      reaches spatial accuracy within the top tier of established datasets <i>while</i> offering
      temporal precision they do not.
    </div>
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>Results at a glance</h2>
    <p class="sec-lede">Every property carries both a high-confidence and a lower-confidence verdict.
    Follow a row for the measurements behind it.</p>
    <div class="tw">
      <table>
        <thead><tr><th>Property</th><th>High confidence</th><th>Lower confidence</th></tr></thead>
        <tbody>
$summaryRows
        </tbody>
      </table>
    </div>
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>Where the Almanac wins, and where it loses</h2>
    <p class="sec-lede">Head-to-head results against named alternatives, in both directions.</p>
    <h3>Ahead</h3>
    <ul>
      <li><strong>Flame length beats Pyrologix at predicting severe fire</strong> - on the identical
      matched test, 0.645 against 0.575 (2021) and 0.789 against 0.677 (2022), the only two years a
      matched comparison is possible.</li>
      <li><strong>Four decades of consistent fire skill.</strong> Flame-length cap20 averages 0.605
      across 39 years, above chance in every one, with little degradation back to the 1980s. No
      alternative product exists over that span to compare against.</li>
      <li><strong>Runoff against 122 gauged basins</strong> - R&sup2; 0.87 in space, 0.83 in time,
      slope 1.01. The strongest external test in the dataset, and independent of Landsat entirely.</li>
      <li><strong>Seam-free across four Landsat changeovers</strong> in every property tested. This is
      the axis the Almanac is built for, and it is not routinely reported elsewhere.</li>
    </ul>
    <h3>Behind</h3>
    <ul>
      <li><strong>Moran's annually-updated FSim burn probability beats WA on all four overlapping
      years</strong>, with a large gap in the high-fire year 2020 (-0.100). WA is also not calibrated
      to absolute burn probability, so level comparisons are not possible.</li>
      <li><strong>Biomass saturates above ~200 Mg/ha</strong>, underestimating growth in mid to older
      stands by up to 80%. The close agreement with GEDI suggests an allometric rather than optical
      cause.</li>
      <li><strong>Diffuse mortality is under-registered</strong> - capture 0.15 against FIA, and
      harvest 0.28. The disturbance layer targets abrupt loss by design.</li>
      <li><strong>No independent evidence for tree-cover change accuracy.</strong> Temporal precision
      is demonstrated; change accuracy against field observation is not, and cannot be from the
      available data.</li>
    </ul>
    <div class="note warn">
      <b>On circularity.</b> Several comparisons here are not independent, and are labelled as such
      rather than presented as validation. All gridded cover products are Landsat-derived; USFS TCC
      trains the Almanac's tree fraction and RAP trains shrub, herb and bare, so only RCMAP is
      independent for all four. MTBS and Hansen share Landsat lineage with the disturbance layer.
      Runoff comparisons are driven on both axes by precipitation of common origin - which is why the
      AET comparisons, which subtract that out, are the stronger evidence. Agreement under circularity
      is a consistency check, not proof.
    </div>
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>By property</h2>
    <div class="cards">
$cards
    </div>
  </div>
</section>

<section class="block">
  <div class="wrap">
    <h2>A work in progress</h2>
    <p>The pipeline reprocesses every year and every property at once, producing a complete new
    version while previous versions are archived. Full reprocessing combined with rigorous
    benchmarking creates a continuous improvement cycle: it allows updates with minimal latency; it
    ties the properties to one another so tradeoffs can be quantified in a way that independently
    assembled datasets cannot support; testing one property informs the others; and it removes any
    hesitancy to make improvements that might otherwise break the time series.</p>
    <p>These results should be read as one turn of that cycle. They document the state of the dataset
    now, and they identify where the next round of development is aimed.</p>
  </div>
</section>
$FOOT
"@
Set-Content -Path (Join-Path $root 'benchmarking.html') -Value $hub -Encoding utf8
Write-Host "  wrote benchmarking.html"
Write-Host "done - $($P.Count) property pages + hub"

