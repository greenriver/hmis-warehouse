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
    this.homelessnessStatus = (this.data.homelessness_statuses || []).filter((d) => d.homelessness_status === this.state.homelessnessStatus)[0] || {}
    
    this.config = this.projectType.config || this.homelessnessStatus.config || {}
    

    this.countLevel = (this.projectType.count_levels || []).filter((d) => d.count_level === this.state.countLevel)[0] || {}
    this.series = this.countLevel.series || this.projectType.series || this.homelessnessStatus.series || []
  }

  test() {
    console.log(this)
  }

  getColumns() {
    return this.series.map((d, i) => {
      return [this.config.keys[i]].concat(
        d.series.filter((n) => {
          if(this.state.dateRange) {
            const [year, month, day] = n.date.split('-')
            const date = Date.parse(new Date(year, month, day))
            const [s, e] = this.state.dateRange
            return date >= s && date <= e
          }
          if(this.state.year) {
            const [year, month, day] = n.date.split('-')
            const date = new Date(year, month, day)
            const stateYear = this.state.year
            return date.getFullYear().toString() === stateYear
          }
          return true
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
        colors: this.config.colors,
        names: this.config.names,
      },
      bindto: this.selector
    }
    return config
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.load({
      columns: this.getColumns(),
    })
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
  
}