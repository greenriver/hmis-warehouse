import { Controller } from "@hotwired/stimulus"
import { bb, bar } from "billboard.js";
import "billboard.js/dist/billboard.css";

// This assumes App.util.copyToClipboard is available globally.
const copyToClipboard = window.App?.util?.copyToClipboard || (() => {
  console.warn("copyToClipboard utility not found.");
});


export default class extends Controller {
  static targets = ["chart", "sourceSelect", "columnsSelect", "clientColsBtn", "enrollmentColsBtn", "defaultColsBtn", "clearColsBtn", "resetBtn", "hideable"];
  static values = {
    counts: Array,
    possibleClientColumns: Array,
    possibleEnrollmentColumns: Array,
    defaultColumns: Array,
  }

  connect() {
    this.hideHideable();
    if (this.hasChartTarget) {
      this.renderChart();
    }
  }

  hideHideable() {
    const selectedValue = this.sourceSelectTarget.value;
    let visibleClass;
    if (selectedValue === 'Data Source') {
      visibleClass = 'datas';
    } else if (selectedValue === 'Organization') {
      visibleClass = 'org';
    } else if (selectedValue === 'Project') {
      visibleClass = 'proj';
    }

    this.hideableTargets.forEach(el => {
      if (visibleClass && el.classList.contains(visibleClass)) {
        el.classList.remove('hidden');
      } else {
        el.classList.add('hidden');
      }
    });
  }

  reset() {
    location.reload();
  }

  clearColumns() {
    this.setSelectedColumns([]);
  }

  selectClientColumns() {
    this.setSelectedColumns(this.possibleClientColumnsValue);
  }

  selectEnrollmentColumns() {
    this.setSelectedColumns(this.possibleEnrollmentColumnsValue);
  }

  selectDefaultColumns() {
    this.setSelectedColumns(this.defaultValueColumns);
  }

  setSelectedColumns(fields) {
    const values = new Set(fields);
    Array.from(this.columnsSelectTarget.options).forEach(option => {
      option.selected = values.has(option.value);
    });
    // Assuming select2 is used, which requires a 'change' event to update its display.
    this.columnsSelectTarget.dispatchEvent(new Event('change', { bubbles: true }));
  }

  renderChart() {
    const data = this.countsValue;
    if (!data.length) return;

    const labels = data.map(a => a[0]);
    const values = data.map(a => a[1].total);

    const chartConfig = {
      bindto: this.chartTarget,
      data: {
        columns: [
          ['counts', ...values]
        ],
        type: bar(),
        labels: {
          format: (v) => v.toLocaleString('en-US')
        },
        onclick: (d, element) => {
          if (!d) return;
          const datum = data[d.index];
          const text = `${datum[0]}: ${datum[1].total}`;
          copyToClipboard(text);
        }
      },
      axis: {
        x: {
          type: 'category',
          categories: labels,
          tick: {
            rotate: 30,
          }
        },
        y: {
          tick: {
            format: (x) => { return x.toLocaleString('en-US'); }
          }
        }
      },
      legend: {
        show: false
      },
      tooltip: {
        format: {
          value: (value, ratio, id, index) => {
            const datum = data[index][1];
            const type = datum.counts_present ? 'present' : 'missing';
            return `${type}: ${value.toLocaleString('en-US')}`;
          }
        }
      },
      color: {
        pattern: ['#091f2f']
      }
    };
    bb.generate(chartConfig);
  }
}
