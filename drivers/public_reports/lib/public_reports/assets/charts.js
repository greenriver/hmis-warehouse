// Build-time chart renderers.
//
// These run once, in Node, while Eleventy builds the site. They return plain
// SVG/HTML strings — no client-side JavaScript, no chart library, nothing
// shipped to the browser. This is what keeps the exported site "vanilla HTML".

const DEFAULT_COLORS = [
  "#14558F", // Bay Blue
  "#2D6A46", // Berkshires Green
  "#F6C51B", // Duckling Yellow
  "#680A1D", // Independence Cranberry
  "#535353", // Granite Gray
  "#4377A5", // Bay Blue hover tint
  "#388557", // Berkshires Green hover tint
];

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[ch]);
}

function formatNumber(value) {
  return new Intl.NumberFormat("en-US").format(value);
}

// Solid for the first series; later series get a dash pattern too, so a
// multi-series line chart doesn't rely on color alone to tell lines apart
// (WCAG 1.4.1, Use of Color) for colorblind or grayscale-printed viewers.
const DASH_PATTERNS = [null, "7,4", "2,3", "1,4,6,4"];

/**
 * Multi-series line chart over a shared set of category labels (e.g. years).
 * series: [{ label, values: number[], color? }]
 * opts.info: trusted, pre-escaped HTML (e.g. an info-icon link) appended
 * after the (escaped) title — see index.njk's infoIcon macro.
 */
function lineChart(series, years, opts = {}) {
  const {
    title = "",
    width = 640,
    height = 200,
    colors = DEFAULT_COLORS,
    info = "",
  } = opts;

  const padding = { top: 16, right: 20, bottom: 30, left: 56 };
  const innerW = width - padding.left - padding.right;
  const innerH = height - padding.top - padding.bottom;

  const allValues = series.flatMap((s) => s.values);
  const maxRaw = Math.max(...allValues, 1);
  const magnitude = Math.pow(10, Math.floor(Math.log10(maxRaw)));
  const niceMax = Math.ceil(maxRaw / magnitude) * magnitude;

  const stepX = years.length > 1 ? innerW / (years.length - 1) : 0;
  const scaleY = (v) => padding.top + innerH - (v / niceMax) * innerH;
  const xAt = (idx) => padding.left + idx * stepX;

  const gridLines = [0, 0.25, 0.5, 0.75, 1]
    .map((f) => {
      const y = padding.top + innerH - f * innerH;
      const val = Math.round(niceMax * f);
      return `<line x1="${padding.left}" y1="${y.toFixed(1)}" x2="${(
        width - padding.right
      ).toFixed(1)}" y2="${y.toFixed(1)}" class="chart-gridline" aria-hidden="true" />
      <text x="${padding.left - 8}" y="${(y + 4).toFixed(
        1
      )}" class="chart-axis-label" text-anchor="end">${formatNumber(
        val
      )}</text>`;
    })
    .join("\n");

  const xLabels = years
    .map(
      (y, i) =>
        `<text x="${xAt(i).toFixed(
          1
        )}" y="${height - 10}" class="chart-axis-label" text-anchor="middle">${escapeHtml(
          y
        )}</text>`
    )
    .join("\n");

  // Polylines + decorative dots only — no per-dot interactivity. Hover/focus
  // now lives on one full-height column per x-index (below), grouping every
  // series' value for that year into a single tooltip/aria-label, closer to
  // the live dashboard's billboard.js tooltip (fetched from its source: one
  // shared tooltip per x-value, not one per point) and a real accessibility
  // win over the old per-dot version — 1 focus stop per year instead of 1
  // per (series x year), each with its own visible focus ring (the shared
  // `[tabindex]:focus-visible` rule in base.css) sized to the full plot
  // height rather than a 4px circle (WCAG 2.5.5 target-size territory).
  const lines = series
    .map((s, i) => {
      const color = s.color || colors[i % colors.length];
      const dash = DASH_PATTERNS[i % DASH_PATTERNS.length];
      const dashAttr = dash ? ` stroke-dasharray="${dash}"` : "";
      const points = s.values
        .map((v, idx) => `${xAt(idx).toFixed(1)},${scaleY(v).toFixed(1)}`)
        .join(" ");
      const dots = s.values
        .map(
          (v, idx) =>
            `<circle class="chart-dot" cx="${xAt(idx).toFixed(1)}" cy="${scaleY(
              v
            ).toFixed(1)}" r="4" fill="${color}" />`
        )
        .join("");
      return `<polyline points="${points}" fill="none" stroke="${color}" stroke-width="2.5"${dashAttr} />${dots}`;
    })
    .join("\n");

  // One focusable/hoverable column per year, spanning the midpoints to its
  // neighbors (clamped to the plot edges) so the hit target is generous
  // rather than a few px around the dot.
  const columns = years
    .map((year, idx) => {
      const center = xAt(idx);
      const leftBound = idx === 0 ? padding.left : (xAt(idx - 1) + center) / 2;
      const rightBound =
        idx === years.length - 1
          ? width - padding.right
          : (center + xAt(idx + 1)) / 2;
      const leftPct = (leftBound / width) * 100;
      const widthPct = ((rightBound - leftBound) / width) * 100;

      const rows = series.map((s, i) => ({
        label: s.label,
        value: s.values[idx],
        color: s.color || colors[i % colors.length],
      }));

      const ariaLabel = `${year}: ${rows
        .map((r) => `${r.label}: ${formatNumber(r.value)}`)
        .join("; ")}`;

      const tooltipRows = rows
        .map(
          (r) =>
            `<div class="chart-tooltip__row"><span class="swatch" style="background:${
              r.color
            };${contrastRingStyle(
              r.color
            )}"></span><span class="chart-tooltip__label">${escapeHtml(
              r.label
            )}</span><span class="chart-tooltip__value">${formatNumber(
              r.value
            )}</span></div>`
        )
        .join("");

      return `<div class="chart-point chart-point--column" style="left:${leftPct.toFixed(
        2
      )}%;width:${widthPct.toFixed(
        2
      )}%" tabindex="0" role="img" aria-label="${escapeHtml(ariaLabel)}">
        <div class="chart-tooltip chart-tooltip--html chart-tooltip--table" aria-hidden="true">
          <div class="chart-tooltip__header">${escapeHtml(year)}</div>
          ${tooltipRows}
        </div>
      </div>`;
    })
    .join("");

  const legend = series
    .map((s, i) => {
      const color = s.color || colors[i % colors.length];
      const dash = DASH_PATTERNS[i % DASH_PATTERNS.length];
      const swatchStyle = dash
        ? `background:repeating-linear-gradient(90deg,${color} 0 3px,transparent 3px 5px)`
        : `background:${color}`;
      return `<li><span class="swatch" style="${swatchStyle};${contrastRingStyle(
        color
      )}"></span>${escapeHtml(s.label)}</li>`;
    })
    .join("");

  // The definitive accessible equivalent, independent of hover/focus/JS —
  // same role this plays for every other chart type in this project.
  // Always visible, no <summary> toggle — see the same choice made for
  // stackedBarChart/donutChart below.
  const dataTable = `<div class="chart-data">
    <table>
      <caption class="visually-hidden">${escapeHtml(title)} — data table</caption>
      <thead>
        <tr><th scope="col">Year</th>${series
          .map((s) => `<th scope="col">${escapeHtml(s.label)}</th>`)
          .join("")}</tr>
      </thead>
      <tbody>
        ${years
          .map(
            (y, idx) =>
              `<tr><th scope="row">${escapeHtml(y)}</th>${series
                .map((s) => `<td>${formatNumber(s.values[idx])}</td>`)
                .join("")}</tr>`
          )
          .join("\n")}
      </tbody>
    </table>
  </div>`;

  return `<figure class="chart chart--line">
  <figcaption class="chart-title">${escapeHtml(title)}${info ? " " + info : ""}</figcaption>
  <div class="chart--line-plot">
    <svg viewBox="0 0 ${width} ${height}" class="chart-svg" preserveAspectRatio="xMidYMid meet" aria-hidden="true" focusable="false">
      ${gridLines}
      ${lines}
      ${xLabels}
    </svg>
    ${columns}
  </div>
  <ul class="chart-legend">${legend}</ul>
  ${dataTable}
</figure>`;
}

/**
 * Donut chart for 2-4 segments that sum to (approximately) 100.
 * segments: [{ label, value, color? }]
 * opts: { title, total }
 */
function donutChart(segments, opts = {}) {
  const { title = "", total = "", colors = DEFAULT_COLORS, id = "", unit = "" } = opts;
  const cx = 21;
  const cy = 21;
  const r = 15.9155;
  const strokeWidth = 8;
  const innerR = r - strokeWidth / 2;
  const outerR = r + strokeWidth / 2;

  // Angle 0 = 12 o'clock, increasing clockwise (matches the stroke-dasharray
  // start point below, which is rotated a quarter-turn via dashoffset=25).
  const toXY = (pct, radius) => {
    const rad = ((pct / 100) * 360 - 90) * (Math.PI / 180);
    return [cx + radius * Math.cos(rad), cy + radius * Math.sin(rad)];
  };

  let cumulative = 0;
  const arcs = segments
    .map((seg, i) => {
      const color = seg.color || colors[i % colors.length];
      const dasharray = `${seg.value} ${100 - seg.value}`;
      const dashoffset = 25 - cumulative;
      const startPct = cumulative;
      const midPct = cumulative + seg.value / 2;
      cumulative += seg.value;

      const label = `${escapeHtml(seg.label)}: ${seg.value}%`;
      // Segment labels alone are ambiguous across donuts that share the same
      // category names (e.g. "Sheltered"/"Unsheltered" appears in both the
      // "All People" and "Veterans" donuts) — the accessible name needs the
      // chart's own subject to disambiguate, even though the on-chart visual
      // tooltip (which sits directly under a visible figcaption already
      // naming that subject) doesn't need to repeat it.
      const ariaLabel = `${escapeHtml(title)}, ${label}`;
      const [tx, ty] = toXY(midPct, outerR + 3);
      const tooltipWidth = Math.max(14, label.length * 2.1 + 3);
      const anchor =
        midPct > 25 && midPct < 75 ? "middle" : midPct <= 25 ? "start" : "end";
      // Divider between this segment and the previous one (white gap), skip
      // for a lone/full-circle segment where there's nothing to divide.
      const [dx1, dy1] = toXY(startPct, innerR);
      const [dx2, dy2] = toXY(startPct, outerR);
      const divider =
        segments.length > 1
          ? `<line data-index="${i}" x1="${dx1.toFixed(2)}" y1="${dy1.toFixed(
              2
            )}" x2="${dx2.toFixed(2)}" y2="${dy2.toFixed(
              2
            )}" class="donut-divider" aria-hidden="true" />`
          : "";

      return `${divider}<g class="chart-point" data-index="${i}">
        <circle class="donut-segment" cx="${cx}" cy="${cy}" r="${r}" fill="transparent" stroke="${color}" stroke-width="${strokeWidth}" stroke-dasharray="${dasharray}" stroke-dashoffset="${dashoffset}" tabindex="0" role="img" aria-label="${ariaLabel}" />
        <g class="chart-tooltip" aria-hidden="true">
          <rect x="${(tx - (anchor === "start" ? 1 : anchor === "end" ? tooltipWidth - 1 : tooltipWidth / 2)).toFixed(
            2
          )}" y="${(ty - 2.5).toFixed(
        2
      )}" width="${tooltipWidth.toFixed(2)}" height="5" rx="1" />
          <text x="${(anchor === "start"
            ? tx - 1 + tooltipWidth / 2
            : anchor === "end"
            ? tx + 1 - tooltipWidth / 2
            : tx
          ).toFixed(2)}" y="${(ty + 0.9).toFixed(
        2
      )}" text-anchor="middle">${label}</text>
        </g>
      </g>`;
    })
    .join("\n");

  const [totalValue, ...totalLabelParts] = String(total).split(" ");
  const totalLabel = totalLabelParts.join(" ");

  // No separate <ul class="chart-legend"> — the data table below doubles as
  // the legend (swatch to the left of each category name), so there's only
  // one place readers need to look for the color key. Always visible, no
  // <summary> toggle, matching stackedBarChart's Racial Composition table.
  // A bare "Sheltered"/"Unsheltered" row label would be ambiguous once two
  // donuts with those same segment names (All People, Veterans) sit next to
  // each other with both tables always open, so each label is suffixed with
  // the donut's own unit unless it already ends with it (e.g. "Children-Only
  // Households" + "Households" would otherwise double up).
  const dataTable = `<div class="chart-data chart-data--legend">
    <table>
      <caption class="visually-hidden">${escapeHtml(title)} — data table</caption>
      <thead>
        <tr><th scope="col">Category</th><th scope="col">Percentage</th></tr>
      </thead>
      <tbody>
        ${segments
          .map((seg, i) => {
            const color = seg.color || colors[i % colors.length];
            const rowLabel =
              unit && !seg.label.endsWith(unit) ? `${seg.label} ${unit}` : seg.label;
            return `<tr><th scope="row"><span class="swatch" style="background:${color};${contrastRingStyle(
              color
            )}"></span>${escapeHtml(
              rowLabel
            )}</th><td>${seg.value}%</td></tr>`;
          })
          .join("\n")}
      </tbody>
    </table>
  </div>`;

  return `<figure class="chart chart--donut" data-component="donut" data-donut-id="${escapeHtml(
    id
  )}">
  <figcaption class="chart-title">${escapeHtml(title)}</figcaption>
  <svg viewBox="0 0 42 42" class="chart-svg chart-svg--donut">
    <title>${escapeHtml(title)}: ${escapeHtml(total)}</title>
    <circle class="donut-ring" cx="${cx}" cy="${cy}" r="${r}" fill="transparent" stroke-width="${strokeWidth}" />
    ${arcs}
    <text x="21" y="19.8" class="donut-total-value" text-anchor="middle">${escapeHtml(
      totalValue
    )}</text>
    <text x="21" y="24.8" class="donut-total-label" text-anchor="middle">${escapeHtml(
      totalLabel
    )}</text>
  </svg>
  ${dataTable}
</figure>`;
}

// Verified against the live dashboard's "who" iframe (billboard.js source,
// fetched 2026-09-14): the 8 race/ethnicity categories share this fixed
// color mapping across both the "Homeless Population" and "Overall
// Population" bars, so the same category always reads as the same color.
const RACE_COLORS = {
  "American Indian, Alaska Native, or Indigenous": "#14558F",
  "Asian or Asian American": "#388557",
  "Black, African American, or African": "#5F7990",
  "Native Hawaiian or Pacific Islander": "#680A1D",
  White: "#3E94CF",
  "Doesn't know, prefers not to answer, or not collected": "#535353",
  "Multi-Racial": "#AD7E88",
  "Other or Unknown": "#C98DFF",
};

// WCAG relative luminance / contrast ratio, used below to pick readable
// inline label text per segment color rather than assuming white always
// works — a few of the fixed race colors (the light blue and light purple
// especially) don't hit 4.5:1 against white text.
function relativeLuminance(hex) {
  const channels = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);
  const linear = channels.map((c) =>
    c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
  );
  return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2];
}

function contrastRatio(l1, l2) {
  const [a, b] = [l1, l2].sort((x, y) => y - x);
  return (a + 0.05) / (b + 0.05);
}

const INK_LUMINANCE = relativeLuminance("#1B1B1B"); // matches --color-ink
const WHITE_LUMINANCE = relativeLuminance("#ffffff");

// Picks whichever of white/ink text reads better against a given fill, and
// reports the ratio it actually achieved — callers use the ratio to decide
// whether an inline label is even safe to show (WCAG 1.4.3 needs >= 4.5:1
// for normal-size text; there's a narrow band of medium-luminance fills
// where neither white nor ink clears that on its own).
function pickTextColor(bgHex) {
  const bgLuminance = relativeLuminance(bgHex);
  const whiteRatio = contrastRatio(bgLuminance, WHITE_LUMINANCE);
  const inkRatio = contrastRatio(bgLuminance, INK_LUMINANCE);
  return whiteRatio >= inkRatio
    ? { color: "#fff", ratio: whiteRatio }
    : { color: "#1B1B1B", ratio: inkRatio };
}

// WCAG 1.4.11 Non-text Contrast: a fill this light against the white page
// background (e.g. Duckling Yellow, or the race chart's light purple) is
// close to invisible on its own. Adds a thin dark ring so the segment/swatch
// stays perceivable as a distinct shape no matter what color sits next to
// it — a box-shadow rather than a border so it doesn't touch flex-basis
// layout. No-op (empty string) for every fill that already clears 3:1.
function contrastRingStyle(bgHex) {
  const ratio = contrastRatio(relativeLuminance(bgHex), WHITE_LUMINANCE);
  return ratio < 3 ? "box-shadow:inset 0 0 0 1px var(--color-ink);" : "";
}

/**
 * Two 100%-stacked horizontal bars (one per population, e.g. "Homeless
 * Population" vs "Overall Population") segmented by a shared category set —
 * plain HTML/CSS flex bars, no SVG needed. Mirrors the live dashboard's
 * Racial Composition chart. rows: [{ label, homelessPct, overallPct }]
 */
function stackedBarChart(rows, opts = {}) {
  const {
    title = "",
    categories = ["A", "B"],
    colors = RACE_COLORS,
    id = "",
  } = opts;
  const [labelA, labelB] = categories;

  function bar(key, populationLabel) {
    const segments = rows
      .map((row, index) => ({ label: row.label, value: row[key], index }))
      .filter((s) => s.value != null && s.value > 0);

    const segmentHtml = segments
      .map((s) => {
        const color = colors[s.label] || "#999";
        const labelText = `${escapeHtml(s.label)}: ${s.value}%`;
        // Same category appears in both bars ("White: 45%" is ambiguous
        // between the "Homeless Population" and "Overall Population" bars)
        // — the accessible name needs the bar's own population label to
        // disambiguate, even though the visible tooltip (directly under
        // this bar's own <p class="stacked-bar__label"> heading) doesn't.
        const ariaLabel = `${escapeHtml(populationLabel)}, ${labelText}`;
        // Inline label only where a segment is wide enough to plausibly fit
        // "NN%" AND the auto-picked text color actually clears 4.5:1 (WCAG
        // 1.4.3) against this exact fill — guards against a future palette
        // color landing in the narrow luminance band where neither white nor
        // ink text reaches 4.5:1 on its own. Below the width threshold it'd
        // either overflow or be squeezed unreadably small anyway. The value
        // is always available via the tooltip and the data table below
        // regardless, so suppressing the inline overlay costs nothing.
        const textChoice = pickTextColor(color);
        const showInlineLabel = s.value >= 8 && textChoice.ratio >= 4.5;
        const inlineLabel = showInlineLabel
          ? `<span aria-hidden="true" style="color:${textChoice.color}">${s.value}%</span>`
          : "";
        // Some segments (e.g. a 1%-wide sliver) render only a few px wide —
        // under WCAG 2.2's 24x24 Target Size (Minimum, 2.5.8), but exempt
        // under that criterion's "essential" exception: the width itself is
        // the data being conveyed, and the always-visible data table below
        // is a full-size alternative way to reach the same info.
        return `<div class="chart-point" data-index="${s.index}" style="flex-basis:${s.value}%">
          <div class="stacked-bar__segment" style="background:${color};${contrastRingStyle(
            color
          )}" tabindex="0" role="img" aria-label="${ariaLabel}">${inlineLabel}</div>
          <div class="chart-tooltip chart-tooltip--html" aria-hidden="true">${labelText}</div>
        </div>`;
      })
      .join("");

    return `<div class="stacked-bar" data-key="${key}">
      <p class="stacked-bar__label">${escapeHtml(populationLabel)}</p>
      <div class="stacked-bar__track">${segmentHtml}</div>
    </div>`;
  }

  // Always expanded, with no collapse affordance — unlike the other chart
  // types' <details>/<summary> table (design.md's accessible-equivalent
  // pattern), this one is small enough, and central enough to this chart's
  // reading, that hiding it behind a toggle just adds a click. Each row
  // repeats its legend swatch so the table doubles as the legend.
  const dataTable = `<div class="chart-data chart-data--legend">
    <table>
      <caption class="visually-hidden">${escapeHtml(title)} — data table</caption>
      <thead>
        <tr><th scope="col">Category</th><th scope="col">${escapeHtml(
          labelA
        )}</th><th scope="col">${escapeHtml(labelB)}</th></tr>
      </thead>
      <tbody>
        ${rows
          .map((row) => {
            const color = colors[row.label] || "#999";
            return `<tr><th scope="row"><span class="swatch" style="background:${color};${contrastRingStyle(
              color
            )}"></span>${escapeHtml(
              row.label
            )}</th><td>${
              row.homelessPct != null ? row.homelessPct + "%" : "—"
            }</td><td>${
              row.overallPct != null ? row.overallPct + "%" : "—"
            }</td></tr>`;
          })
          .join("\n")}
      </tbody>
    </table>
  </div>`;

  // role="group"/aria-labelledby ties the bars + table to this chart's own
  // title — a plain <div><p> pair has no native grouping semantics the way
  // <figure><figcaption> does for the donut chart above.
  const titleId = `chart-title-${escapeHtml(id || "chart")}`;
  return `<div class="chart chart--stacked-bar" data-component="stacked-bar" data-chart-id="${escapeHtml(
    id
  )}" role="group" aria-labelledby="${titleId}">
  <p class="chart-title" id="${titleId}">${escapeHtml(title)}</p>
  ${bar("homelessPct", labelA)}
  ${bar("overallPct", labelB)}
  ${dataTable}
</div>`;
}

/**
 * Single 100%-stacked horizontal bar for one population's composition
 * (e.g. Household Type) — segments: [{ label, value, color? }], values sum
 * to ~100. Reuses .chart--stacked-bar's CSS (segment dividers, tooltip
 * anchoring) rather than introducing a parallel set of bar styles, and the
 * same swatch-legend data table pattern as donutChart/stackedBarChart.
 */
function compositionBarChart(segments, opts = {}) {
  const { title = "", colors = DEFAULT_COLORS, id = "", unit = "" } = opts;

  const segmentHtml = segments
    .map((seg, i) => {
      const color = seg.color || colors[i % colors.length];
      const labelText = `${escapeHtml(seg.label)}: ${seg.value}%`;
      // See stackedBarChart's identical guard above: only show the inline
      // overlay once it both fits (>= 8% wide) and actually clears 4.5:1
      // (WCAG 1.4.3) against this fill.
      const textChoice = pickTextColor(color);
      const showInlineLabel = seg.value >= 8 && textChoice.ratio >= 4.5;
      const inlineLabel = showInlineLabel
        ? `<span aria-hidden="true" style="color:${textChoice.color}">${seg.value}%</span>`
        : "";
      // A narrow sliver (e.g. 1%) renders only a few px wide — exempt from
      // WCAG 2.2's 2.5.8 Target Size (Minimum) under its "essential"
      // exception, since the width itself is the data, and the always-
      // visible data table below is a full-size alternative to reach it.
      return `<div class="chart-point" data-index="${i}" style="flex-basis:${seg.value}%">
        <div class="stacked-bar__segment" style="background:${color};${contrastRingStyle(
          color
        )}" tabindex="0" role="img" aria-label="${labelText}">${inlineLabel}</div>
        <div class="chart-tooltip chart-tooltip--html" aria-hidden="true">${labelText}</div>
      </div>`;
    })
    .join("");

  const dataTable = `<div class="chart-data chart-data--legend">
    <table>
      <caption class="visually-hidden">${escapeHtml(title)} — data table</caption>
      <thead>
        <tr><th scope="col">Category</th><th scope="col">Percentage</th></tr>
      </thead>
      <tbody>
        ${segments
          .map((seg, i) => {
            const color = seg.color || colors[i % colors.length];
            const rowLabel =
              unit && !seg.label.endsWith(unit) ? `${seg.label} ${unit}` : seg.label;
            return `<tr><th scope="row"><span class="swatch" style="background:${color};${contrastRingStyle(
              color
            )}"></span>${escapeHtml(
              rowLabel
            )}</th><td>${seg.value}%</td></tr>`;
          })
          .join("\n")}
      </tbody>
    </table>
  </div>`;

  // role="group"/aria-labelledby ties the bar + table to this chart's own
  // title, same rationale as stackedBarChart above.
  const titleId = `chart-title-${escapeHtml(id || "chart")}`;
  return `<div class="chart chart--stacked-bar chart--composition-bar" data-component="composition-bar" data-chart-id="${escapeHtml(
    id
  )}" role="group" aria-labelledby="${titleId}">
  <p class="chart-title" id="${titleId}">${escapeHtml(title)}</p>
  <div class="stacked-bar">
    <div class="stacked-bar__track">${segmentHtml}</div>
  </div>
  ${dataTable}
</div>`;
}

// This file is also passthrough-copied to /js/charts.js and loaded as a
// plain <script> by src/js/who-section.js, so the exact same render
// functions produce the donut/stacked-bar markup on quarter/grouping change
// as they did at Eleventy build time — no separate client-side
// reimplementation of the arc/flex-basis geometry to keep in sync. `module`
// doesn't exist in that context, hence the guard.
const charts = { lineChart, donutChart, stackedBarChart, compositionBarChart };
if (typeof module !== "undefined" && module.exports) {
  module.exports = { charts };
}
if (typeof window !== "undefined") {
  window.Charts = charts;
}

