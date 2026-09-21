// The only client-side JavaScript in this project. It exists to swap the
// per-county color/table data when the two dropdowns in the "where is the
// need" section change — everything else on the page is static HTML/CSS,
// including the map geometry and the initially-selected period/group, which
// are rendered server-side by src/lib/townMap.js. See design.md.
(function () {
  "use strict";

  // Rate per 10,000 residents, live THDSN map's own real bands — see the
  // matching comment on BANDS in src/lib/townMap.js for the source.
  var BANDS = [
    { max: 0, color: "#FFFFFF", label: "0 per 10,000" },
    { max: 3, color: "#D7E1FF", label: "Any – 3 per 10,000" },
    { max: 6, color: "#A7B5DC", label: "4 – 6 per 10,000" },
    { max: 9, color: "#778ABA", label: "7 – 9 per 10,000" },
    { max: 12, color: "#476299", label: "10 – 12 per 10,000" },
    { max: 15, color: "#003D79", label: "13 – 15 per 10,000" },
    { max: 18, color: "#CC7E6E", label: "16 – 18 per 10,000" },
    { max: Infinity, color: "#FB6CCF", label: "19+ per 10,000" },
  ];

  var NOT_REPORTING_COLOR = "#EDEDED";

  function bandFor(rate) {
    for (var i = 0; i < BANDS.length; i++) {
      if (rate <= BANDS[i].max) return BANDS[i];
    }
    return BANDS[BANDS.length - 1];
  }

  function bandColor(rate) {
    return rate == null ? NOT_REPORTING_COLOR : bandFor(rate).color;
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
  function formatRateBand(rate) {
    return rate == null ? "Not currently reporting to THDSN" : bandFor(rate).label;
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
        path.style.fill = bandColor(rate);
        var title = path.querySelector("title");
        if (title) {
          title.textContent =
            rate == null
              ? data.towns[i] + ": not currently reporting to THDSN"
              : data.towns[i] + ": " + rate + " per 10,000 residents (" + bandFor(rate).label + ")";
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
          formatNumber(total) +
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
        formatRateBand(rate) +
        "</dd></div>" +
        "<div><dt>" +
        escapeHtml(groupLabel) +
        ", statewide</dt><dd>" +
        formatNumber(statewideTotal) +
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

