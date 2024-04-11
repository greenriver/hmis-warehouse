class AllNeighborsSystemDashboardQuarters {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = this.state = initialState
    this.selector = selector
    this.scale = {
      x: d3.scaleBand(this.data.map((d) => d.name), [0, 100]).paddingOuter(0.1)
    }
    // this never changes so we don't need to redraw
    this.container = d3.select(selector)
    this.container.style('position', 'relative')
    this.container.style('height', '62px')
    this.barContainer = this.container.append('div')
      .style('position', 'relative')
      .style('height', '10px')
      .style('background-color', '#E1E1E1')
      .style('border-radius', '20px')
    this.axis = this.container.selectAll('.quarter-text')
      .data(this.data)
      .join('div')
        .attr('class', 'quarter-text')
        .style('position', 'absolute')
        .style('width', `${this.scale.x.bandwidth()}%`)
        .style('left', (d) => `${this.scale.x(d.name)}%`)
        .style('bottom', '0px')
        .style('text-align', 'center')
        .style('font-weight', (d) => d.name.indexOf('Q1') > -1 ? 'bold' : 'normal')
        .html((d) => {
          const [quarter, year] = d.name.split(' ')
          return `<span>${quarter}</span></br><span>${year}</span>`
        })
  }

  left(d) {
    return `${this.scale.x(d[0])}%`
  }

  right(d) {
    if(d[0] === d[1]) {
      return `${100 - (this.scale.x(d[0]) + this.scale.x.bandwidth())}%`
    }
    return `${100 - (this.scale.x(d[1]) + this.scale.x.bandwidth())}%`
  }

  redraw(state) {
    this.state = state
    this.draw()
  }

  draw() {
    this.barContainer.selectAll('.bar')
      .data([this.state.quarterRange])
      .join(
        (enter) => {
          return enter.append('div')
            .attr('class', 'bar')
            .style('position', 'absolute')
            .style('left', (d) => this.left(d))
            .style('right', (d) => this.right(d))
            .style('top', '0px')
            .style('bottom', '0px')
            .style('background-color', '#AC7979')

        },
        (update) => {
          return update
            .transition()
            .style('left', (d) => this.left(d))
            .style('right', (d) => this.right(d))
        },
        (exit) => exit
      )
  }
}
globalThis.AllNeighborsSystemDashboardQuarters = AllNeighborsSystemDashboardQuarters;
