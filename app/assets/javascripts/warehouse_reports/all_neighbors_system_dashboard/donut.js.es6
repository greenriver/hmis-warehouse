class AllNeighborsSystemDashboardDonut {

  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
  }

  init() {
    this.projectType = (this.data.project_types || []).filter((d) => d.project_type === this.state.projectType)[0] || {}
    this.config = this.projectType.config || {}
    this.countLevel = (this.projectType.count_levels || []).filter((d) => d.count_level === this.state.countLevel)[0] || {}
    this.series = this.countLevel.series || []
  }

  test() {
    console.log(this)
  }

  getColumns() {
    return this.series.map((d, i) => {
      return [this.config.keys[i]].concat(
        d.series.filter((n) => {
          const date = Date.parse(n.date)
          const [s, e] = this.state.dateRange
          return date >= s && date <= e
        })
        .map((s) => s.values[0])
      )
    })
  }

  getConfig() {
    const config = {
      data: {
        columns: this.getColumns(),
        type: 'donut',
        colors: this.projectType.config.colors,
        names: this.projectType.config.names,
      },
      bindto: this.selector
    }
    return config
  }

  redraw(state) {
    this.state = state
    this.init()
    console.log('redraw', this)
    this.chart.load({
      columns: this.getColumns(),
    })
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
  
}