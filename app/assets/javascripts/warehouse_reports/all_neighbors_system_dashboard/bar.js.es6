class AllNeighborsSystemDashboarBar {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
  }

  init() {
    
    this.series = (this.data.series || []).filter((d) => !d.table_only)
    this.config = this.data.config
  }

  getConfig() {
    return {
      data: {
        x: "x",
        columns: [
          ["x"].concat(this.config.keys)
        ].concat(this.series.map((d) => [d.name].concat(d.values))),
        types: {
          exited: "bar",
          returned: "bar",
        },
        colors: {
          exited: (d) => this.config.colors[d.id][d.index],
          returned: (d) => this.config.colors[d.id][d.index],
        },
        labels: {
          show: true,
          color: '#000000',
        },
      },
      axis: {
        x: {
          type: "category",
        }
      },
      legend: {
        show: false,
      },
      bindto: this.selector
    }
  }

  test() {
    console.log(this)
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}