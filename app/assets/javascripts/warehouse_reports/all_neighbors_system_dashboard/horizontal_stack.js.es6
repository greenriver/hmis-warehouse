class AllNeighborsSystemDashboardHorizontalStack {
  
  constructor(data, initialState, selector) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.init()
  }

  init() {
    this.project = this.data.filter((d) => d.project_type === this.state.projectType)[0]
    this.countLevel = this.project ? (this.project.count_levels || []).filter((d) => d.count_level_name === this.state.countLevel)[0] : null
    this.series = this.countLevel ? this.countLevel.primary : []
  }

  test() {
    console.log('this')
  }

  getColumn(name) {
    let col = [name]
    if(name === 'x') {
      col.push(this.project.project_type)
      return col.concat(this.countLevel.comparative.map((d, i) => d.name))
    } else {
      const index = this.project.column_keys.indexOf(name)
      let total = 0
      this.series.forEach((d) => {
        const date = Date.parse(d.date)
        const [s, e] = this.state.dateRange
        if(date >= s && date <= e) {
          total += d.series[index]
        }
      })
      col.push(total)
      this.countLevel.comparative.forEach((d) => {
        col.push(d.series[index])
      })
      return col
    }
  }

  getConfig() {
    return {
      data: {
        x: "x",
        columns: [
          this.getColumn('x'),
        ].concat(this.project.column_keys.map((d) => this.getColumn(d))),
        type: "bar",
        colors: this.project.colors,
        names: this.project.column_names,
        groups: [this.project.column_keys],
        labels: {
          show: true,
          centered: true,
          colors: '#FFFFFF',
        },
        stack: {
          normalize: true
        }
      },
      axis: {
        rotated: true,
        x: {
          type: "category"
        }
      },
      bindto: this.selector
    }
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.load({
      columns: [
          this.getColumn('x'),
        ].concat(this.project.column_keys.map((d) => this.getColumn(d)))
    })
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}