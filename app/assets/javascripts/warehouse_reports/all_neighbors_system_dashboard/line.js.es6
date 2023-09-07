class AllNeighborsSystemDashboardLine {
  constructor(data, initialState, selector) {
    console.log('AllNeighborsSystemDashboardLine')
    this.data = data
    this.state = initialState
    this.selector = selector
    this.project = this.data.filter((d) => d.project_type === this.state.projectType)[0]
    this.countLevel = this.project ? (this.project.count_levels || []).filter((d) => d.count_level_name === this.state.countLevel)[0] : null
    this.series = this.countLevel ? this.countLevel.series : []
  }

  test() {
    console.log('data', this.data)
    console.log('state', this.state)
  }

  getColumns(name) {
    let cols = [name]
    this.series.forEach((d) => {
      const date = Date.parse(d[0])
      const [s, e] = this.state.dateRange
      if(date >= s && date <= e) {
        const [x, y] = d
        cols.push(name === "x" ? x : y)
      }
    })
    return cols
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
      axis: {
        x: {
          type: "timeseries",
          tick: {
            values: this.series.map(function(d) {
              return d[0]
            }),
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