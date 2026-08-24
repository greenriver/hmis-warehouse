import { Controller } from "@hotwired/stimulus"
import { bb, area } from "billboard.js";
import "billboard.js/dist/billboard.css";

const TOP_USERS_SHOWN = 20;

export default class extends Controller {
  static values = { data: Object };
  static targets = ["kpis", "reportSearch", "reportsBody", "usersBody", "showMoreUsers", "chart", "chartInsight"];

  connect() {
    this.reportSort = { key: "unique_visits", dir: "desc" };
    this.reportFilter = "";
    this.expandedReports = new Set();

    this.renderKpis();
    this.renderReportsTable();
    this.renderUsersTable();
    this.renderChart();
  }

  get reports() {
    return this.dataValue.reports || [];
  }

  get userTotals() {
    return this.dataValue.user_totals || {};
  }

  get users() {
    return this.dataValue.users || {};
  }

  get totalVisitDays() {
    return this.reports.reduce((sum, r) => sum + r.unique_visits, 0);
  }

  userLabel(id) {
    const entry = this.users[id];
    return entry ? entry.label : `User #${id}`;
  }

  userLinkHtml(id) {
    const entry = this.users[id];
    const label = this.escapeHtml(this.userLabel(id));
    if (!entry || !entry.edit_url) return label;

    return `<a href="${this.escapeHtml(entry.edit_url)}">${label}</a>`;
  }

  escapeHtml(value) {
    const div = document.createElement("div");
    div.textContent = value == null ? "" : String(value);
    return div.innerHTML.replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  // ---- KPI tiles ----
  renderKpis() {
    if (!this.hasKpisTarget) return;

    const mostUsedReport = this.reports.reduce((best, r) => (!best || r.unique_visits > best.unique_visits ? r : best), null);
    const userEntries = Object.entries(this.userTotals);
    const mostActiveUser = userEntries.reduce((best, [id, count]) => (!best || count > best[1] ? [id, count] : best), null);

    const tiles = [
      { label: "Reports with activity", value: this.reports.length },
      { label: "Users with activity", value: Object.keys(this.userTotals).length },
      { label: "Total visit-days", value: this.totalVisitDays.toLocaleString() },
      {
        label: "Most-used report",
        value: mostUsedReport ? mostUsedReport.unique_visits.toLocaleString() : "—",
        sub: mostUsedReport ? mostUsedReport.name : "",
      },
      {
        label: "Most active user",
        value: mostActiveUser ? mostActiveUser[1].toLocaleString() : "—",
        sub: mostActiveUser ? this.userLabel(mostActiveUser[0]) : "",
      },
    ];

    this.kpisTarget.innerHTML = tiles
      .map(
        (t) => `
      <div class="col">
        <div class="card h-100">
          <div class="card-body">
            <div class="small">${this.escapeHtml(t.label)}</div>
            <div class="fs-2 mb-0 fw-bolder">${this.escapeHtml(t.value)}</div>
            ${t.sub ? `<div class="small text-truncate" title="${this.escapeHtml(t.sub)}">${this.escapeHtml(t.sub)}</div>` : ""}
          </div>
        </div>
      </div>`,
      )
      .join("");
  }

  // ---- Report usage table ----
  sortReports(event) {
    const key = event.currentTarget.dataset.key;
    if (this.reportSort.key === key) {
      this.reportSort.dir = this.reportSort.dir === "asc" ? "desc" : "asc";
    } else {
      this.reportSort = { key, dir: key === "name" ? "asc" : "desc" };
    }
    this.renderReportsTable();
  }

  filterReports(event) {
    this.reportFilter = event.target.value;
    this.renderReportsTable();
  }

  toggleReportRow(event) {
    const key = event.currentTarget.dataset.reportKey;
    if (this.expandedReports.has(key)) {
      this.expandedReports.delete(key);
    } else {
      this.expandedReports.add(key);
    }
    this.renderReportsTable();
  }

  renderReportsTable() {
    if (!this.hasReportsBodyTarget) return;

    const filtered = this.reports.filter((r) => r.name.toLowerCase().includes(this.reportFilter.toLowerCase()));
    const dir = this.reportSort.dir === "asc" ? 1 : -1;
    const sorted = filtered.slice().sort((a, b) => {
      const av = a[this.reportSort.key];
      const bv = b[this.reportSort.key];
      if (typeof av === "string") return av.localeCompare(bv) * dir;
      return (av - bv) * dir;
    });

    const maxVisits = Math.max(1, ...this.reports.map((r) => r.unique_visits));

    this.reportsBodyTarget.innerHTML = sorted
      .map((r) => {
        const share = this.totalVisitDays ? (r.unique_visits / this.totalVisitDays) * 100 : 0;
        const avg = r.unique_users ? r.unique_visits / r.unique_users : 0;
        const fillPct = ((r.unique_visits / maxVisits) * 100).toFixed(1);

        const row = `
        <tr class="usage-report-row" role="button" data-report-key="${this.escapeHtml(r.key)}" data-action="click->access-logs-usage-report#toggleReportRow">
          <td class="text-truncate" style="max-width: 320px;" title="${this.escapeHtml(r.name)}">${this.escapeHtml(r.name)}</td>
          <td class="text-end">${r.unique_users}</td>
          <td class="text-end">${r.unique_visits}</td>
          <td class="text-end">${avg.toFixed(1)}</td>
          <td class="text-end">${share.toFixed(1)}%</td>
          <td style="width: 140px;">
            <div class="progress" style="height: 8px;">
              <div class="progress-bar" style="width: ${fillPct}%"></div>
            </div>
          </td>
        </tr>`;

        return this.expandedReports.has(r.key) ? row + this.drilldownRowHtml(r) : row;
      })
      .join("");
  }

  drilldownRowHtml(report) {
    const entries = Object.entries(report.user_visits || {}).sort((a, b) => b[1] - a[1]);
    const rows = entries
      .map(([userId, count]) => {
        const share = report.unique_visits ? (count / report.unique_visits) * 100 : 0;
        return `<tr><td>${this.userLinkHtml(userId)}</td><td class="text-end">${count}</td><td class="text-end">${share.toFixed(1)}%</td></tr>`;
      })
      .join("");

    return `
      <tr>
        <td colspan="6" class="bg-light">
          <p class="text-muted small mb-2">${entries.length} user${entries.length === 1 ? "" : "s"} visited this report</p>
          <table class="table table-sm mb-0">
            <thead><tr><th>User</th><th class="text-end">Visit-days</th><th class="text-end">Share</th></tr></thead>
            <tbody>${rows}</tbody>
          </table>
        </td>
      </tr>`;
  }

  // ---- Top users table ----
  showAllUsers() {
    if (!this.hasUsersBodyTarget) return;

    this.usersBodyTarget.querySelectorAll("tr.usage-report-hidden-user").forEach((tr) => tr.classList.remove("d-none"));
    if (this.hasShowMoreUsersTarget) this.showMoreUsersTarget.classList.add("d-none");
  }

  renderUsersTable() {
    if (!this.hasUsersBodyTarget) return;

    const entries = Object.entries(this.userTotals)
      .map(([id, count]) => ({ id, count }))
      .sort((a, b) => b.count - a.count);

    this.usersBodyTarget.innerHTML = entries
      .map((u, i) => {
        const share = this.totalVisitDays ? (u.count / this.totalVisitDays) * 100 : 0;
        const hiddenClass = i >= TOP_USERS_SHOWN ? "usage-report-hidden-user d-none" : "";
        return `
        <tr class="${hiddenClass}">
          <td class="text-end">${i + 1}</td>
          <td>${this.userLinkHtml(u.id)}</td>
          <td class="text-end">${u.count.toLocaleString()}</td>
          <td class="text-end">${share.toFixed(1)}%</td>
        </tr>`;
      })
      .join("");

    if (this.hasShowMoreUsersTarget) {
      const remaining = entries.length - TOP_USERS_SHOWN;
      if (remaining > 0) {
        this.showMoreUsersTarget.textContent = `Show all ${entries.length} users`;
        this.showMoreUsersTarget.classList.remove("d-none");
      } else {
        this.showMoreUsersTarget.classList.add("d-none");
      }
    }
  }

  // ---- Concentration chart: single axis (cumulative % of total visit-days) ----
  renderChart() {
    if (!this.hasChartTarget) return;

    const sorted = this.reports.slice().sort((a, b) => b.unique_visits - a.unique_visits);
    const n = sorted.length;
    if (!n) return;

    let cumulative = 0;
    const points = sorted.map((r, i) => {
      cumulative += r.unique_visits;
      return {
        rank: i + 1,
        name: r.name,
        visits: r.unique_visits,
        cumPct: this.totalVisitDays ? (cumulative / this.totalVisitDays) * 100 : 0,
      };
    });

    const milestone80 = points.find((p) => p.cumPct >= 80);
    const gridLines = [50, 80]
      .map((milestone) => {
        const hit = points.find((p) => p.cumPct >= milestone);
        if (!hit) return null;
        return { value: milestone, text: `${milestone}% · ${hit.rank} report${hit.rank === 1 ? "" : "s"}`, position: "start" };
      })
      .filter(Boolean);

    bb.generate({
      bindto: this.chartTarget,
      data: {
        x: "rank",
        columns: [
          ["rank", ...points.map((p) => p.rank)],
          ["Cumulative % of visit-days", ...points.map((p) => p.cumPct)],
        ],
        type: area(),
      },
      axis: {
        x: { tick: { values: [1, n], outer: false } },
        y: { min: 0, max: 100, tick: { values: [0, 25, 50, 75, 100], format: (v) => `${v}%` }, padding: { top: 0, bottom: 0 } },
      },
      grid: { y: { lines: gridLines }, focus: { show: false } },
      legend: { show: false },
      point: { show: false },
      tooltip: {
        contents: (d) => {
          const point = points[d[0].index];
          if (!point) return "";

          return `
            <div style="background:#fff;border:1px solid rgba(0,0,0,0.15);border-radius:4px;box-shadow:0 2px 6px rgba(0,0,0,0.15);font-size:0.85rem;min-width:220px;overflow:hidden;">
              <div style="background:#6c757d;color:#fff;font-weight:600;padding:6px 10px;">${this.escapeHtml(point.name)}</div>
              <div style="display:flex;align-items:center;gap:6px;padding:6px 10px;">
                <span style="display:inline-block;width:10px;height:10px;background:#2a78d6;border-radius:2px;flex:none;"></span>
                <span>${point.visits.toLocaleString()} visit-days · rank ${point.rank} of ${n} · ${point.cumPct.toFixed(1)}% cumulative</span>
              </div>
            </div>`;
        },
      },
      color: { pattern: ["#2a78d6"] },
    });

    if (this.hasChartInsightTarget) {
      this.chartInsightTarget.textContent = milestone80
        ? `${milestone80.rank} of ${n} reports (${((milestone80.rank / n) * 100).toFixed(0)}%) account for 80% of all visit-days.`
        : "";
    }
  }
}
