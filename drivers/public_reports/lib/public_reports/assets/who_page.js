// The second (and last) piece of client-side JS in this project, alongside
// src/js/town-map.js. It wires up the shared "Choose time period" dropdown
// (which updates the three donuts, the Racial Composition bar, and every
// demographic-breakdown row) and the "Choose grouping" dropdown (which just
// shows/hides pre-rendered sections). See design.md and
// src/lib/whoSection.js for why this exists and how the sample data works.
//
// Rather than hand-duplicating the donut arc / stacked-bar geometry math in
// this file, it loads the exact same render functions used at Eleventy
// build time (window.Charts from /js/charts.js, window.WhoSection from
// /js/who-lib.js — passthrough copies of src/lib/charts.js and
// src/lib/whoSection.js) and calls them again with the newly-selected
// period's data, replacing the relevant element's outerHTML. The breakdown
// rows' small sheltered/unsheltered bars are simple/stable enough in
// structure to update in place instead.
(function () {
  "use strict";

  document.querySelectorAll('[data-component="who-section"]').forEach(function (root) {
    var dataEl = root.querySelector("[data-who-data]");
    if (!dataEl || !window.Charts || !window.WhoSection) return;
    var data = JSON.parse(dataEl.textContent);

    var periodSelect = root.querySelector("[data-who-period]");
    var groupingSelect = root.querySelector("[data-who-grouping]");

    function updateDonuts(periodIdx) {
      Object.keys(data.donuts).forEach(function (id) {
        if (id === "household-type") return;
        var d = data.donuts[id];
        var figure = root.querySelector(
          '.chart--donut[data-donut-id="' + id + '"]'
        );
        if (!figure) return;
        var values = d.values[periodIdx];
        var segments = d.labels.map(function (label, i) {
          return { label: label, value: values[i] };
        });
        var total = window.WhoSection.formatTotal(d.totals[periodIdx], d.unit);
        figure.outerHTML = window.Charts.donutChart(segments, {
          title: d.title,
          total: total,
          id: id,
          colors: d.colors || undefined,
          unit: d.unit,
        });
      });
    }

    function updateHouseholdType(periodIdx) {
      var id = "household-type";
      var d = data.donuts[id];
      var chart = root.querySelector(
        '.chart--composition-bar[data-chart-id="' + id + '"]'
      );
      if (!d || !chart) return;
      var values = d.values[periodIdx];
      var segments = d.labels.map(function (label, i) {
        return { label: label, value: values[i] };
      });
      var total = window.WhoSection.formatTotal(d.totals[periodIdx], d.unit);
      chart.outerHTML = window.Charts.compositionBarChart(segments, {
        title: total,
        id: id,
        colors: d.colors || undefined,
        unit: d.unit,
      });
    }

    function updateRace(periodIdx) {
      var chart = root.querySelector(
        '.chart--stacked-bar[data-chart-id="race"]'
      );
      if (!chart) return;
      var homeless = data.race.homeless[periodIdx];
      var rows = data.race.labels.map(function (label, i) {
        return {
          label: label,
          homelessPct: homeless[i],
          overallPct: data.race.overall[i],
        };
      });
      var total = window.WhoSection.formatTotal(data.race.totals[periodIdx], "People");
      chart.outerHTML = window.Charts.stackedBarChart(rows, {
        title: total,
        categories: data.raceTitleCategories,
        colors: data.race.colors,
        id: "race",
      });
    }

    function updateBreakdownRows(periodIdx) {
      Object.keys(data.breakdown).forEach(function (rowId) {
        var row = data.breakdown[rowId];
        var total = row.totals[periodIdx];
        var chronicPct = row.chronic[periodIdx];

        var totalEl = root.querySelector('[data-row-total="' + rowId + '"]');
        if (totalEl) totalEl.textContent = window.WhoSection.formatTotal(total, "People");

        var chronicEl = root.querySelector(
          '[data-row-chronic="' + rowId + '"]'
        );
        if (chronicEl) chronicEl.textContent = chronicPct + "%";

        var chronicFullEl = root.querySelector(
          '[data-row-chronic-full="' + rowId + '"]'
        );
        if (chronicFullEl) chronicFullEl.textContent = chronicPct + "% Chronically Homeless";

        var bar = root.querySelector(
          '.breakdown-bar[data-row-id="' + rowId + '"]'
        );
        if (bar) {
          // Read the row's own demographic label from its sibling in the
          // DOM (not part of the JSON payload) so the aria-label can name
          // it — otherwise every row's bar re-announces as the same
          // generic "Sheltered: 8,460" with nothing to tell rows apart.
          var rowEl = bar.closest(".breakdown-row");
          var rowLabelEl = rowEl && rowEl.querySelector(".breakdown-row__label");
          var rowLabel = rowLabelEl ? rowLabelEl.textContent : "";

          var shelteredCount = row.sheltered ? row.sheltered[periodIdx] : null;
          var unshelteredCount = row.unsheltered ? row.unsheltered[periodIdx] : null;
          var redacted = shelteredCount == null || unshelteredCount == null;

          bar.outerHTML = window.WhoSection.renderBreakdownBar(
            rowId,
            rowLabel,
            shelteredCount,
            unshelteredCount,
            redacted
          );
        }
      });
    }

    function updateCurrentPeriodLabels(periodIdx) {
      root.querySelectorAll("[data-who-current-period]").forEach(function (el) {
        el.textContent = data.periods[periodIdx];
      });
    }

    function announcePeriod(periodIdx) {
      var status = root.querySelector("[data-who-period-status]");
      if (status) status.textContent = "Showing data for " + data.periods[periodIdx] + ".";
    }

    function updatePeriod(isInitial) {
      var periodIdx = Number(periodSelect.value);
      updateDonuts(periodIdx);
      updateHouseholdType(periodIdx);
      updateRace(periodIdx);
      updateBreakdownRows(periodIdx);
      updateCurrentPeriodLabels(periodIdx);
      // The initial render fills placeholders on load, not a real change —
      // the live region stays silent until the reader actually picks a
      // different period (see the markup comment on data-who-period-status).
      if (!isInitial) announcePeriod(periodIdx);
    }

    function updateGrouping() {
      var groupingKey = groupingSelect.value;
      root.querySelectorAll(".breakdown-section").forEach(function (section) {
        section.classList.toggle(
          "breakdown-section--hidden",
          section.getAttribute("data-grouping") !== groupingKey
        );
      });
    }

    if (periodSelect) periodSelect.addEventListener("change", function () { updatePeriod(false); });
    if (groupingSelect) groupingSelect.addEventListener("change", updateGrouping);

    updatePeriod(true);
  });
})();

