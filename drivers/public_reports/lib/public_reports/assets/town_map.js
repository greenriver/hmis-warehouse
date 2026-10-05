// Swaps the map colors, table and statewide note when the period or group changes.
(function () {
  "use strict";

  function el(tag, text) {
    var node = document.createElement(tag);
    if (text != null) node.textContent = text;
    return node;
  }

  // Bands and the "not reporting" color are Rails-supplied (data.bands /
  // data.notReportingColor) rather than hard-coded, so they track the
  // report's own MapData#colors palette. A null max means "no upper bound".
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

  // Full rate, for the always-visible data table.
  function formatRate(rate) {
    return rate == null ? "Not reporting" : rate.toLocaleString("en-US");
  }

  // Band label only, for the hover/focus info box, so it shows a grouped
  // category rather than an exact per-geography figure.
  function formatRateBand(rate, bands) {
    return rate == null ? "Not currently reporting" : bandFor(rate, bands).label;
  }

  // Statewide totals follow the same "100 or fewer" redaction convention
  // as the rest of the report, rather than the generic "—" placeholder.
  function formatStatewideTotal(total) {
    return total == null ? "100 or fewer" : total.toLocaleString("en-US");
  }

  function formatNumber(value) {
    return value == null ? "Not reporting" : value.toLocaleString("en-US");
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
    var infoPlaceholder = infoBox ? Array.from(infoBox.childNodes, function (n) { return n.cloneNode(true); }) : [];
    var paths = root.querySelectorAll(".town-map__town");
    var isPercentage = data.unit.indexOf("Percentage") === 0;

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
              ? data.towns[i] + ": Not reporting"
              : data.towns[i] + ": " + rate.toLocaleString("en-US") + (isPercentage ? "%" : "");
        }
      });

      var rows = data.towns
        .map(function (name, i) {
          return { name: name, rate: rates[i], population: data.populations[i] };
        })
        .sort(function (a, b) {
          return (b.rate == null ? -1 : b.rate) - (a.rate == null ? -1 : a.rate);
        });

      tbody.replaceChildren.apply(
        tbody,
        rows.map(function (row) {
          var tr = el("tr");
          tr.append(
            el("td", row.name),
            el("td", formatRate(row.rate) + (row.rate != null && isPercentage ? "%" : "")),
            el("td", formatNumber(row.population))
          );
          return tr;
        })
      );

      if (statewideNote) {
        var total = data.statewideTotals[periodIdx][groupIdx];
        statewideNote.textContent =
          "Statewide total, " +
          data.groups[groupIdx] +
          ", " +
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
          tableWrap.dataset.labelPrefix +
            ", " +
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
      var stats = el("dl");
      stats.className = "town-map__info-stats";
      [
        [groupLabel + " within " + name, formatRateBand(rate, data.bands)],
        [groupLabel + ", statewide", formatStatewideTotal(statewideTotal) + " people"],
        ["Census population", formatNumber(population)],
      ].forEach(function (pair) {
        var div = el("div");
        div.append(el("dt", pair[0]), el("dd", pair[1]));
        stats.append(div);
      });
      var heading = el("h4", name);
      heading.className = "town-map__info-name";
      infoBox.replaceChildren(heading, stats);
    }

    function resetTownInfo() {
      if (!infoBox) return;
      delete infoBox.dataset.activeIndex;
      infoBox.replaceChildren.apply(infoBox, infoPlaceholder.map(function (n) { return n.cloneNode(true); }));
    }

    periodSelect.addEventListener("change", update);
    groupSelect.addEventListener("change", update);

    // Sighted-mouse-only enhancement: every value shown here also lives in
    // the table, which needs neither a mouse nor JavaScript to read.
    if (svg && infoBox) {
      svg.addEventListener("mouseover", function (e) {
        var path = e.target.closest(".town-map__town");
        if (path) showTownInfo(Number(path.dataset.index));
      });
      svg.addEventListener("mouseleave", resetTownInfo);
    }
  });
})();

