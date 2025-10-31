import { Controller } from "@hotwired/stimulus"
import { bb, bar, line } from "billboard.js";
import "billboard.js/dist/billboard.css";

export default class extends Controller {
  static targets = ["chart"];
  static values = {
    data: Array,
    metricName: String,
    entityLabel: String
  }

  connect() {
    if (this.hasChartTarget && this.dataValue.length > 0) {
      this.renderChart();
    }
  }

  renderChart() {
    const data = this.dataValue;
    if (!data.length) return;

    // Data comes as [[date, count], [date, count], ...]
    const dates = data.map(d => d[0]);
    const counts = data.map(d => d[1]);
    const entityLabel = this.entityLabelValue || 'Entities';

    const chartConfig = {
      bindto: this.chartTarget,
      data: {
        x: 'dates',
        columns: [
          ['dates', ...dates],
          ['Threshold Crossings', ...counts]
        ],
        type: bar(),
        labels: {
          format: (v) => v > 0 ? v.toLocaleString('en-US') : ''
        }
      },
      axis: {
        x: {
          type: 'timeseries',
          tick: {
            format: '%Y-%m-%d',
            rotate: 45,
            fit: true,
            culling: {
              max: 15
            }
          }
        },
        y: {
          label: {
            text: `Number of ${entityLabel}`,
            position: 'outer-middle'
          },
          tick: {
            format: (x) => { return Math.floor(x).toLocaleString('en-US'); }
          }
        }
      },
      legend: {
        show: false
      },
      tooltip: {
        format: {
          title: (d) => {
            const date = new Date(d);
            return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
          },
          value: (value) => {
            const label = entityLabel.toLowerCase();
            return `${value.toLocaleString('en-US')} ${label}${value !== 1 ? 's' : ''} crossed threshold`;
          }
        }
      },
      color: {
        pattern: ['#288be4']
      },
      padding: {
        bottom: 20
      }
    };

    bb.generate(chartConfig);
  }
}
