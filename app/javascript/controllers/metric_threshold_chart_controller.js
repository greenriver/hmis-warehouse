import { Controller } from "@hotwired/stimulus"
import { bb, bar, line } from "billboard.js";
import "billboard.js/dist/billboard.css";

export default class extends Controller {
  static targets = ["chart", "detailsContainer"];
  static values = {
    data: Array,
    metricName: String,
    entityLabel: String,
    metricId: Number
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
        },
        onclick: (d) => this.handleBarClick(d)
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

    this.chart = bb.generate(chartConfig);
  }

  async handleBarClick(d) {
    if (!d || !d.x) return;

    const date = new Date(d.x);
    const dateString = date.toISOString().split('T')[0];

    // Show loading state
    if (this.hasDetailsContainerTarget) {
      this.detailsContainerTarget.style.display = 'block';
      this.detailsContainerTarget.innerHTML = '<p>Loading...</p>';
    }

    try {
      const url = `/admin/metric_definitions/${this.metricIdValue}/crossings_for_date?date=${dateString}`;
      const response = await fetch(url);
      const jsonData = await response.json();

      this.renderDetailsTable(jsonData);
    } catch (error) {
      console.error('Error fetching crossings:', error);
      if (this.hasDetailsContainerTarget) {
        this.detailsContainerTarget.innerHTML = '<p class="text-danger">Error loading data. Please try again.</p>';
      }
    }
  }

  renderDetailsTable(data) {
    if (!data.crossings || data.crossings.length === 0) {
      if (this.hasDetailsContainerTarget) {
        this.detailsContainerTarget.innerHTML = '<p class="text-muted">No crossings found for this date.</p>';
      }
      return;
    }

    const entityLabel = this.entityLabelValue || 'Client';
    const tableHTML = `
      <h4>Threshold Crossings on ${data.date}</h4>
      <table class="table table-striped">
        <thead>
          <tr>
            <th>${entityLabel} ID</th>
            <th>Previous Value</th>
            <th>New Value</th>
            <th>Change</th>
          </tr>
        </thead>
        <tbody>
          ${data.crossings.map(crossing => {
      const change = crossing.change;
      const sign = change > 0 ? '+' : '';
      const linkHTML = crossing.entity_url
        ? `<a href="${crossing.entity_url}">${entityLabel} #${crossing.entity_id}</a>`
        : `${entityLabel} #${crossing.entity_id}`;
      return `
              <tr>
                <td>${linkHTML}</td>
                <td>${crossing.previous_value || 'N/A'}</td>
                <td>${crossing.current_value}</td>
                <td>${sign}${change}</td>
              </tr>
            `;
    }).join('')}
        </tbody>
      </table>
    `;

    if (this.hasDetailsContainerTarget) {
      this.detailsContainerTarget.innerHTML = tableHTML;
    }
  }
}
