// Shows the selected period's server-rendered charts in the "Who is
// experiencing homelessness?" section, and the selected breakdown grouping.
(function () {
  "use strict";

  document.querySelectorAll('[data-component="who-section"]').forEach(function (root) {
    var periodSelect = root.querySelector("[data-who-period]");
    var groupingSelect = root.querySelector("[data-who-grouping]");
    var status = root.querySelector("[data-who-period-status]");

    function updatePeriod() {
      var periodIdx = periodSelect.value;
      var label = periodSelect.options[periodSelect.selectedIndex].text;
      root.querySelectorAll("[data-who-period-pane]").forEach(function (pane) {
        pane.hidden = pane.getAttribute("data-who-period-pane") !== periodIdx;
      });
      root.querySelectorAll("[data-who-current-period]").forEach(function (el) {
        el.textContent = label;
      });
      if (status) status.textContent = "Showing data for " + label + ".";
    }

    function updateGrouping() {
      var groupingKey = groupingSelect.value;
      root.querySelectorAll(".breakdown-section").forEach(function (section) {
        section.classList.toggle("breakdown-section--hidden", section.getAttribute("data-grouping") !== groupingKey);
      });
      var label = groupingSelect.options[groupingSelect.selectedIndex].text;
      root.querySelectorAll("[data-who-grouping-label]").forEach(function (el) {
        el.textContent = label;
      });
    }

    if (periodSelect) periodSelect.addEventListener("change", updatePeriod);
    if (groupingSelect) groupingSelect.addEventListener("change", updateGrouping);
  });
})();
