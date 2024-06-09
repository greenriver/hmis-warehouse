// Because this needs to be inlined for PDF generation, we don't actually import from
// the base chart, we include the base chart file and use globalThis
// import HmisDqToolChart from './hmis_dq_tool_chart'

class HmisDqToolCompleteness extends HmisDqToolChart {
  constructor(data, chart_selector) {
    super(data, chart_selector)
    this._set_columns = this._set_columns.bind(this);
    this._colors = this._colors.bind(this);
    this.data = data;
    this.chart_selector = chart_selector;
    this._set_columns();
    this.data = this._format_data(this.data)
    this.color_map = {}
    this.next_color = 0
  }

  _set_columns() {
    return this.columns = this.data.columns;
  }

  _format_data(data) {
    return {
      labels: data.labels,
      data: data.data,
      order: "asc",
      groups: [
        [
          'Valid',
          'Invalid',
        ]
      ]
    };
  }

  _calculate_height() {
    return this.data.labels.length * 50;
  }

  build_chart() {
    if ($(this.chart_selector).length === 0) { return; }
    return this.chart = bb.generate({
      bindto: this.chart_selector,
      size: {
        height: this._calculate_height()
      },
      data: {
        json: this.data['data'],
        type: "bar",
        order: this.data['order'],
        groups: this.data['groups'],
        color: this._colors,
        types: {
          "Valid": "bar",
          "Invalid": "bar",
          'Target': "line"
        }
      },
      point: {
        show: false
      },
      line: {
        classes: [
          'data-quality__target-line'
        ]
      },
      axis: {
        rotated: true,
        x: {
          type: "category",
          categories: this.data['labels'],
          tick: {
            multiline: false
          }
        },
        range: {
          min: {
            y: -100
          }
        },
        y: {
          padding: 0,
          max: 100
        }
      },
      grid: {
        y: {
          lines: {
            value: 0
          }
        }
      },
      tooltip: {
        format: {
          value(v) {
            return `${v}%`;
          }
        }
      }
    });
  }
};
globalThis.HmisDqToolCompleteness = HmisDqToolCompleteness;
