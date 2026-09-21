// Build-time renderer for the "Who is experiencing homelessness?" card:
// three donuts (All People / Veterans / Household Type), the Racial
// Composition stacked bar, and the "Choose grouping" demographic breakdown
// (Household Type / Gender / Race), all driven by one shared "Choose time
// period" dropdown — mirroring the live dashboard's single quarter slider,
// confirmed by fetching its `who` iframe source directly (2026-09-14).
//
// Also passthrough-copied to /js/who-lib.js and loaded as a plain <script>
// by src/js/who-section.js, which is the second (and last) piece of
// client-side JS in this project. On quarter/grouping change, that script
// reuses these exact same functions (donutChart/stackedBarChart from
// charts.js, plus renderBreakdownBar below) rather than reimplementing the
// arc/flex-basis geometry — see the `require`/`window` guard below and in
// charts.js. See design.md for the sample-data rationale.

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

function formatTotal(n, unit) {
  if (n == null || n < 100) return `less than 100 ${unit}`;
  return `${formatNumber(n)} ${unit}`;
}

// Every subsection repeats this note, so a page with N subsections has N
// "change time period" links all pointing at the same #who-period-select —
// fine per WCAG 2.4.4 (identical text + identical destination is allowed),
// but a screen-reader user browsing by links list hears the same phrase N
// times with nothing to tell them apart. sectionName adds that context
// visually-hidden so the on-screen text stays unchanged.
function periodNote(currentPeriodLabel, sectionName) {
  return `<p class="who-controls__period-note">Showing data for <strong data-who-current-period>${currentPeriodLabel}</strong> — <a href="#who-period-select">change time period<span class="visually-hidden"> for ${escapeHtml(
    sectionName
  )}</span></a></p>`;
}

// --- Rendering ---

// A small sheltered/unsheltered (or solid gray "redacted") bar for one
// breakdown row. Structurally stable across quarters (redacted-ness never
// changes), so the client only ever needs to resize the two segments, not
// rebuild this markup — kept intentionally simpler than the full
// stackedBarChart()/donutChart() reuse used for the donuts and race chart.
// `label` (the row's own demographic label, e.g. "Woman", "Persons Age 18 to
// 24") is folded into every aria-label here — without it, every row in a
// ~14-row breakdown announces as the same generic "Sheltered: 8,460"/
// "Unsheltered: …" with nothing to tell them apart. The adjacent visible
// tooltip can stay shorter since it sits directly under this row's own
// `.breakdown-row__label` text.
function renderBreakdownBar(rowId, label, shelteredCount, unshelteredCount, redacted) {
  if (redacted) {
    return `<div class="breakdown-bar" data-row-id="${rowId}">
      <div class="breakdown-bar__track">
        <div class="breakdown-bar__segment breakdown-bar__segment--redacted" style="flex-basis:100%" tabindex="0" role="img" aria-label="${escapeHtml(
          label
        )}: sheltered/unsheltered breakdown unavailable for this group"></div>
      </div>
    </div>`;
  }
  const total = shelteredCount + unshelteredCount;
  const shelteredPct = total > 0 ? Math.round((shelteredCount / total) * 100) : 0;
  const unshelteredPct = 100 - shelteredPct;
  return `<div class="breakdown-bar" data-row-id="${rowId}">
    <div class="breakdown-bar__track">
      <div class="chart-point" data-segment="sheltered" style="flex-basis:${shelteredPct}%">
        <div class="breakdown-bar__segment breakdown-bar__segment--sheltered" tabindex="0" role="img" aria-label="${escapeHtml(
          label
        )}, Sheltered: ${formatNumber(shelteredCount)}"></div>
        <div class="chart-tooltip chart-tooltip--html" aria-hidden="true">Sheltered: ${formatNumber(
          shelteredCount
        )}</div>
      </div>
      <div class="chart-point" data-segment="unsheltered" style="flex-basis:${unshelteredPct}%">
        <div class="breakdown-bar__segment breakdown-bar__segment--unsheltered" tabindex="0" role="img" aria-label="${escapeHtml(
          label
        )}, Unsheltered: ${formatNumber(unshelteredCount)}"></div>
        <div class="chart-tooltip chart-tooltip--html" aria-hidden="true">Unsheltered: ${formatNumber(
          unshelteredCount
        )}</div>
      </div>
    </div>
  </div>`;
}

function renderBreakdownRow(rowId, label, rowData, periodIdx) {
  const total = rowData.totals[periodIdx];
  const chronicPct = rowData.chronic[periodIdx];
  const shelteredCount = rowData.sheltered ? rowData.sheltered[periodIdx] : null;
  const unshelteredCount = rowData.unsheltered ? rowData.unsheltered[periodIdx] : null;
  const redacted = shelteredCount == null || unshelteredCount == null;
  return `<div class="breakdown-row">
    <div class="breakdown-row__label">${escapeHtml(label)}</div>
    <div class="breakdown-row__bar">${renderBreakdownBar(
      rowId,
      label,
      shelteredCount,
      unshelteredCount,
      redacted
    )}</div>
    <div class="breakdown-row__total" data-row-total="${rowId}">${escapeHtml(
    formatTotal(total, "People")
  )}</div>
    <div class="breakdown-row__chronic">
      <span class="visually-hidden" data-row-chronic-full="${rowId}">${chronicPct}% Chronically Homeless</span>
      <span class="breakdown-row__chronic-pct" data-row-chronic="${rowId}" aria-hidden="true">${chronicPct}%</span>
      <span class="breakdown-row__chronic-label" aria-hidden="true">Chronically Homeless</span>
    </div>
  </div>`;
}

function renderGroupingSection(groupingKey, grouping, breakdownData, periodIdx, isVisible) {
  const sectionsHtml = grouping.sections
    .map((section, sectionIdx) => {
      const rowsHtml = section.rows
        .map((row, rowIdx) => {
          const rowId = `${groupingKey}__${sectionIdx}__${rowIdx}`;
          return renderBreakdownRow(rowId, row.label, breakdownData[rowId], periodIdx);
        })
        .join("");
      const heading = section.heading
        ? `<h4 class="breakdown-section__heading">${escapeHtml(section.heading)}</h4>`
        : "";
      return `<div class="breakdown-section__group">${heading}${rowsHtml}</div>`;
    })
    .join("");

  return `<div class="breakdown-section${
    isVisible ? "" : " breakdown-section--hidden"
  }" data-grouping="${groupingKey}">${sectionsHtml}</div>`;
}

const lib = {
  renderGroupingSection,
  renderBreakdownBar,
  renderBreakdownRow,
  formatTotal,
  formatNumber,
};

if (typeof module !== "undefined" && module.exports) {
  module.exports = lib;
}
if (typeof window !== "undefined") {
  window.WhoSection = lib;
}

