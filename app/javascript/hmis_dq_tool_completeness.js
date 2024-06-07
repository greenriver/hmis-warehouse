/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

class HmisDqToolCompleteness {
  constructor(data, chart_selector) {
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
    console.log(this.data)
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

  _colors(c, d) {
    let color;
    let key = d;
    if (key.id != null) {
      key = key.id;
    }
    const colors = ['#091f2f', '#fb4d42', '#288be4', '#d2d2d2'];
    if (['Goal', 'Average', 'Target'].includes(key)) {
      color = 'rgb(228, 228, 228)';
    } else {
      color = this.color_map[key];
      if ((color == null)) {
        color = colors[this.next_color++];
        this.color_map[key] = color;
        this.next_color = this.next_color % colors.length;
      }
    }
    return color;
  }
};
globalThis.HmisDqToolCompleteness = HmisDqToolCompleteness;
