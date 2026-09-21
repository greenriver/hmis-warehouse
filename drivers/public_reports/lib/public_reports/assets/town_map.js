// The only client-side JavaScript in this project. It exists to swap the
// per-county color/table data when the two dropdowns in the "where is the
// need" section change — everything else on the page is static HTML/CSS,
// including the map geometry and the initially-selected period/group, which
// are rendered server-side by src/lib/townMap.js. See design.md.
(function () {
  "use strict";

  // Bands and the "not reporting" color are Rails-supplied (data.bands /
  // data.notReportingColor) rather than hard-coded, so they track the
  // report's own map_colors palette. A null max (none sent today, but the
  // shape allows it) means "no upper bound".
  function bandFor(rate, bands) {
    for (var i = 0; i < bands.length; i++) {
      var max = bands[i].max == null ? Infinity : bands[i].max;
      if (rate <= max) return bands[i];
    }
    return bands[bands.length - 1];
  }

  function bandColor(rate, bands, notReportingColor) {
    return rate == null ? notReportingColor : bandFor(rate, bands).color;
  }

  // Full rate, for the always-visible data table (this build's sample data
  // is already flagged as illustrative, so there's no real small-number-
  // suppression reason to hide it there).
  function formatRate(rate) {
    return rate == null ? "Not reporting" : rate.toLocaleString("en-US");
  }

  // Band label only, for the hover/focus info box — mirrors the live
  // THDSN map's own privacy design (confirmed from its source, 2026-09-18:
  // its info box shows a grouped category, e.g. "13 - 15 per 10,000", never
  // an exact per-county figure) rather than the precise sample number.
  function formatRateBand(rate, bands) {
    return rate == null ? "Not currently reporting to THDSN" : bandFor(rate, bands).label;
  }

  // Statewide totals follow the same "less than 100" redaction convention
  // as the rest of the report, rather than the generic "—" placeholder.
  function formatStatewideTotal(total) {
    return total == null ? "less than 100" : total.toLocaleString("en-US");
  }

  function escapeHtml(value) {
    return String(value).replace(/[&<>"']/g, function (ch) {
      return (
        { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[
          ch
        ] || ch
      );
    });
  }

  function formatNumber(value) {
    return value == null ? "—" : value.toLocaleString("en-US");
  }

  document.querySelectorAll('[data-component="town-map"]').forEach(function (root) {
    var dataEl = root.querySelector("[data-town-map-data]");
    if (!dataEl) return;
    var data = JSON.parse(dataEl.textContent);

    var periodSelect = root.querySelector("[data-town-map-period]");
    var groupSelect = root.querySelector("[data-town-map-group]");
    var tbody = root.querySelector("[data-town-map-tbody]");
    var tableWrap = root.querySelector("[data-town-map-table-wrap]");
    var statewideNote = root.querySelector("[data-town-map-statewide]");
    var svg = root.querySelector("[data-town-map-svg]");
    var infoBox = root.querySelector("[data-town-map-info]");
    var infoPlaceholderHtml = infoBox ? infoBox.innerHTML : "";
    var paths = root.querySelectorAll(".town-map__town");

    function update() {
      var periodIdx = Number(periodSelect.value);
      var groupIdx = Number(groupSelect.value);
      var rates = data.values[periodIdx][groupIdx];

      paths.forEach(function (path) {
        var i = Number(path.dataset.index);
        var rate = rates[i];
        path.style.fill = bandColor(rate, data.bands, data.notReportingColor);
        var title = path.querySelector("title");
        if (title) {
          title.textContent =
            rate == null
              ? data.towns[i] + ": not currently reporting to THDSN"
              : data.towns[i] + ": " + rate + " per 10,000 residents (" + bandFor(rate, data.bands).label + ")";
        }
      });

      var rows = data.towns
        .map(function (name, i) {
          return { name: name, rate: rates[i], population: data.populations[i] };
        })
        .sort(function (a, b) {
          return (b.rate == null ? -1 : b.rate) - (a.rate == null ? -1 : a.rate);
        });

      tbody.innerHTML = rows
        .map(function (row) {
          return (
            "<tr><td>" +
            escapeHtml(row.name) +
            "</td><td>" +
            formatRate(row.rate) +
            "</td><td>" +
            formatNumber(row.population) +
            "</td></tr>"
          );
        })
        .join("");

      if (statewideNote) {
        var total = data.statewideTotals[periodIdx][groupIdx];
        statewideNote.textContent =
          data.groups[groupIdx] +
          ", statewide, " +
          data.periods[periodIdx] +
          ": " +
          formatStatewideTotal(total) +
          " people";
      }

      // Keeps the scrollable region's accessible name naming whichever
      // period/group is currently selected — the table's cells update in
      // place above, so without this a screen reader user re-entering the
      // region would still hear the name from whatever was selected when
      // the page loaded.
      if (tableWrap) {
        tableWrap.setAttribute(
          "aria-label",
          "Rate per 10,000 residents by county, " +
            data.groups[groupIdx] +
            ", " +
            data.periods[periodIdx] +
            ". Scrollable table."
        );
      }

      // The hover info box (if currently showing a county) reflects
      // whichever period/group is selected, same as everything else on the
      // map.
      if (infoBox && infoBox.dataset.activeIndex !== undefined) {
        showTownInfo(Number(infoBox.dataset.activeIndex));
      }
    }

    function showTownInfo(index) {
      if (!infoBox) return;
      var periodIdx = Number(periodSelect.value);
      var groupIdx = Number(groupSelect.value);
      var name = data.towns[index];
      var rate = data.values[periodIdx][groupIdx][index];
      var statewideTotal = data.statewideTotals[periodIdx][groupIdx];
      var groupLabel = data.groups[groupIdx];
      var population = data.populations[index];

      infoBox.dataset.activeIndex = String(index);
      infoBox.innerHTML =
        '<h4 class="town-map__info-name">' + escapeHtml(name) + "</h4>" +
        '<dl class="town-map__info-stats">' +
        "<div><dt>" +
        escapeHtml(groupLabel) +
        " within " +
        escapeHtml(name) +
        "</dt><dd>" +
        formatRateBand(rate, data.bands) +
        "</dd></div>" +
        "<div><dt>" +
        escapeHtml(groupLabel) +
        ", statewide</dt><dd>" +
        formatStatewideTotal(statewideTotal) +
        " people</dd></div>" +
        "<div><dt>Census population</dt><dd>" +
        formatNumber(population) +
        "</dd></div>" +
        "</dl>";
    }

    function resetTownInfo() {
      if (!infoBox) return;
      delete infoBox.dataset.activeIndex;
      infoBox.innerHTML = infoPlaceholderHtml;
    }

    periodSelect.addEventListener("change", update);
    groupSelect.addEventListener("change", update);

    // Sighted-mouse-only enhancement (see the markup comment in
    // townMap.js) — every value shown here also lives in the table, which
    // needs neither a mouse nor JavaScript to read.
    if (svg && infoBox) {
      svg.addEventListener("mouseover", function (e) {
        var path = e.target.closest(".town-map__town");
        if (path) showTownInfo(Number(path.dataset.index));
      });
      svg.addEventListener("mouseleave", resetTownInfo);
    }
  });
})();

