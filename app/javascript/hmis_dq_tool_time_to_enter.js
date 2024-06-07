class HmisDqToolTimeToEnter {
  constructor(data, chart_selector) {
    this._colors = this._colors.bind(this);
    this.data = data;
    this.chart_selector = chart_selector;
    this.color_map = {};
    this.next_color = 0;
  }

  build_chart() {
    return this.chart = bb.generate({
      bindto: this.chart_selector,
      size: {
        height: 350
      },
      data: {
        json: this.data['data'],
        type: "bar",
        color: this._colors,
        types: {
          "Goal": "line"
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
        x: {
          type: "category",
          categories: this.data['labels'],
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
    if (['Goal'].includes(key)) {
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
globalThis.HmisDqToolTimeToEnter = HmisDqToolTimeToEnter;
