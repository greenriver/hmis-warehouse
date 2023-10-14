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

  inDateRange(dateString, range) {
    const [year, month, day] = dateString.split('-')
    //ruby date month is 1 based while js date month is 0
    const date = Date.parse(new Date(year, month-1, day))
    const [s, e] = range
    return date >= s && date <= e
  }

  getColumns() {
    // console.log(this)
    return this.series.map((d, i) => {
      return [this.config.keys[i]].concat(
        d.series.filter((n) => {

          if(this.state.dateRange) {
            return this.inDateRange(n.date, this.state.dateRange)
          }
          if(this.state.year) {
            const [year, month, day] = n.date.split('-')
            const date = new Date(year, month-1, day)
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
        labels: {
          show: true,
          colors: this.config.label_colors,
        }
      },
      size: {
        width: 220,
        height: 220,
      },
      padding: false,
      bindto: this.selector,
      donut: {
        label: {
          format: (value, ratio, id) => {
            return d3.format(".0%")(ratio)
          }
        },
      }
    }
    if(this.options.legend) {
      const legendData = this.options.legend
      config.legend = {
        contents: {
          bindto: legendData.selector,
          template: (title, color) => {
            const swatch = `<svg class="chart-legend-item-swatch-prs1 mb-2" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
            return `<div class="chart-legend-item-prs1">${swatch}<div class="chart-legend-item-label-prs1">${this.config.names[title]}</div></div>`;
          },
        },
      }
    }
    return config
  }

  updateLabels() {
    const selector = this.options.countLevelLabelSelector
    if(selector) {
      const sum = d3.sum(
        this.getColumns().map((col) => d3.sum(col.slice(1)))
      )
      const label = this.countLevel.count_level || 'Individuals'
      $(selector).text(`${d3.format(',')(sum)} ${label}`)
    }
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.load({
      columns: this.getColumns(),
    })
    this.updateLabels()
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
    this.updateLabels()
  }

}
