class AllNeighborsSystemDashboardLine {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
  }

  init() {
    this.projectType = (this.data.project_types || []).filter((d) => d.project_type === this.state.projectType)[0] || {}
    this.countLevel = (this.projectType.count_levels || []).filter((d) => d.count_level === this.state.countLevel)[0] || {}
    this.series = this.countLevel.series || []
  }

  test() {
    console.log(this)
  }

  getColumns(name) {
    let cols = [name]
    this.series.forEach((d) => {
      const [year, month, day] = d[0].split('-')
      const date = Date.parse(new Date(year, month, day))
      const [s, e] = this.state.dateRange
      if(date >= s && date <= e) {
        const [x, y] = d
        cols.push(name === "x" ? x : y)
      }
    })
    return cols
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.load({
      columns: [
        this.getColumns("x"),
        this.getColumns("total")
      ],
    })
  }

  draw() {
    this.chart = bb.generate({
      data: {
        x: "x",
        columns: [this.getColumns("x"), this.getColumns("total")],
        type: 'line',
        colors: {
          total: "#832C5A",
        },
        names: {
          total: "Total Placements"
        },
      },
      grid: {
        y: {
          show: true
        }
      },
      axis: {
        x: {
          type: "timeseries",
          tick: {
            format: function(d) {
              var names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec']
              var month = names[d.getMonth()]
              var year = d.getFullYear()
              return month + ' ' + year
            }
          }
        }
      },
      bindto: this.selector
    })
  }
}