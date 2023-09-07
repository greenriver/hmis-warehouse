class AllNeighborsSystemDashboardDonut {

  constructor(data, initialState, selector) {
    console.log('AllNeighborsSystemDashboardDonut')
    this.data = data
    this.state = initialState
    this.selector = selector
  }

  test() {
    console.log('data', this.data)
    console.log('state', this.state)
    console.log('config', this.getConfig())
  }

  getColumns() {
    return this.data.map((d) => {
      let col = [d.key]
      d.series.forEach((n) => {
        if(this.state.dateRange) {
          const date = Date.parse(n[0])
          const [s, e] = this.state.dateRange
          if(date >= s && date <= e) {
            col.push(n[1])
          }
        } else {
          col.push(n[0])
        }
        
      })
      return col
    })
  }

  getColors() {
    let colors = {}
    this.data.forEach((d) => {
      colors[d.key] = d.color
    })
    return colors
  }

  getNames() {
    let names = {}
    this.data.forEach((d) => {
      names[d.key] = d.name
    })
    return names
  }

  getConfig() {
    const config = {
      data: {
        columns: this.getColumns(),
        type: 'donut',
        colors: this.getColors(),
        names: this.getNames(),
      },
      bindto: this.selector
    }
    return config
  }

  draw() {
    bb.generate(this.getConfig())
  }
  
}