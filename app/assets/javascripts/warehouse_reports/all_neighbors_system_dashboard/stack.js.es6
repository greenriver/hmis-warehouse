class AllNeighborsSystemDashboardStack {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
  }

  init() {
    this.project = (this.data.project_types || []).filter((d) => d.project_type === this.state.projectType)[0] || {}
    this.homelessnessStatus = (this.data.homelessness_statuses || []).filter((d) => d.homelessness_status === this.state.homelessnessStatus)[0] || {}

    this.countLevel = (this.project.count_levels || []).filter((d) => d.count_level === this.state.countLevel)[0] || {}
    this.householdType = (this.project.household_types || []).filter((d) => d.household_type === this.state.householdType)[0] || {}
    
    this.demographic = (this.householdType.demographics || this.data.demographics || []).filter((d) => d.demographic === this.state.demographics)[0] || {}
    
    this.config = this.project.config || this.homelessnessStatus.config || this.demographic.config || this.data.config || {}
    
    this.series = this.homelessnessStatus.series || this.demographic.series || this.countLevel.series || this.data.series || []
  }

  test() {
    console.log(this)
  }

  getColumn(name) {
    let col = [name]
    if(name === 'x') {
      return col.concat(this.series.map((d) => d.name))
    } else {
      const index = this.config.keys.indexOf(name)
      this.series.forEach((d) => {
        const total = d.series.filter((n) => {
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
        .map((s) => s.values[index])
        .reduce((sum, s) => sum + s, 0)
        col.push(total)
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
        ].concat(this.config.keys.map((d) => this.getColumn(d))),
        type: "bar",
        colors: this.config.colors,
        names: this.config.names,
        groups: [this.config.keys],
        labels: {
          show: true,
          centered: true,
          colors: this.config.label_colors,
        },
        stack: {
          normalize: this.options.normalize,
        }
      },
      axis: {
        rotated: this.options.rotated,
        x: {
          type: "category",
          tick: {
            width: 200,
          }
        }
      },
      padding: this.options.padding,
      bar: {
        width: 50,
      },
      bindto: this.selector
    }
  }

  redraw(state) {
    const old_columns = [...this.config.keys]
    this.state = state
    this.init()
    
    const unload = old_columns.filter((old) => this.config.keys.indexOf(old) === -1)

    this.chart.load({
      columns: [
          this.getColumn('x'),
        ].concat(this.config.keys.map((d) => this.getColumn(d))),
      colors: this.config.colors,
      names: this.config.names,
      unload: unload
    })
    this.chart.internal.config.data_groups = [this.config.keys]
    this.chart.internal.config.data_labels_colors = this.config.label_colors
    this.chart.show()
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}