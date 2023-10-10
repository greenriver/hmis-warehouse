class AllNeighborsSystemDashboarBar {
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
    this.cohort = (this.countLevel.cohorts || []).filter((d) => d.cohort === this.state.cohort)[0] || {}

    this.series = (this.cohort.series || this.data.series || []).filter((d) => !d.table_only)
    this.config = this.cohort.config || this.data.config || {}
  }

  getColumns() {
    return [
      ["x"].concat(this.config.keys)
    ].concat(this.series.map((d) => [d.name].concat(d.values)))
  }

  getDataConfig() {
    return {
      x: "x",
      columns: this.getColumns(),
      types: this.series.reduce((n, d) => ({...n, [d.name]: 'bar'}), {}),
      colors: this.series.reduce((n, d) => {
        return {...n, [d.name]: (d) => this.config.colors[d.id][d.index]}
      }, {}),
      labels: {
        centered: false,
        show: true,
        color: '#000000',
      },
    }
  }

  getAxisConfig() {
    return {
      x: {
        type: "category",
        tick: {
          text: {
            position: {
              x: 0,
              y: 20,
            }
          }
        }
      },
      y: {
        tick: {
          stepSize: 250,
        }
      }
    }
  }

  getConfig() {
    return {
      size: {
        width: $(this.selector).width(),
        height: 500,
      },
      data: this.getDataConfig(),
      padding: {
        left: 60,
        top: 40,
        right: 0,
        bottom: 40
      },
      bar: {
        width: 200,
      },
      grid: {
        y: {show: true}
      },
      axis: this.getAxisConfig(),
      legend: {
        show: false,
      },
      bindto: this.selector,
      onrendered: function() {
        const selector = this.config().bindto
        const data = this.data()
        const percentages = data[0].values.map((d, i) => {
          const returned = data[1].values[i]
          return returned.value/d.value
        })
        data.forEach((d, i) => {
          const barGroup = d3.select(`${selector} .bb-bars-${d.id}`)
          barGroup.attr('transform', i === 0 ? 'translate(15, 0)' : 'translate(-15, 0)')
          const textGroup = d3.select(`${selector} .bb-texts-${d.id}`)
          textGroup.attr('transform', i === 0 ? 'translate(15, 0)' : 'translate(-15, 0)')
          textGroup.selectAll('text').attr('text-anchor', i === 0 ? 'start' : 'end')
          const bar = barGroup.select(`.bb-bar-${i}`)
          const barBox = bar.node().getBBox()
          const text = textGroup.selectAll('text')
          text.attr('transform', i === 0 ? `translate(${barBox.width/2*-1}, -20)` : `translate(${barBox.width/2}, -20)`)
          const xYears = this.config().data.columns[0].slice(1)
          text.each(function(t, ti) {
            const ele = d3.select(this)
            const currentLabel = ele.text()
            ele.text('')
            const label = i === 0 ? `Exited in ${xYears[ti].split(' ')[0]}` : 'Returned in 1 year'
            ele.selectAll('tspan')
              .data([currentLabel, label])
              .join('tspan')
                .attr('x', ele.attr('x'))
                .attr('y', ele.attr('y'))
                .attr('dy', (d, di) => di === 0 ? 0 : 17)
                .text((d, di) => i === 0 ? d : di == 0 ? d3.format('.1%')(percentages[ti]) : d)
          })
          
        })
      }
    }
  }

  test() {
    console.log(this)
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

class AllNeighborsSystemDashboarHorizontalBar extends AllNeighborsSystemDashboarBar {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
  }

  init() {
    super.init()
    this.names = {
      total: `${this.countLevel.count_level} in Cohort`,
      returned: `${this.countLevel.count_level} returned to homelessness`
    }
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.load({
      columns: this.getColumns(),
    })
  }

  getDataConfig() {
    const superDataConfig = super.getDataConfig()
    const data = {
      names: this.names,
      colors: this.series.reduce((n, d) => {
        return {...n, [d.name]: (d) => {
          const hex = this.config.colors[this.config.keys[d.x]]
          if(d.id === 'total') {
            return hex
          } else {
            const color = d3.color(hex)
            color.opacity = 0.5
            return color.toString()
          }
        }}
      }, {}),
    }
    return {...superDataConfig, ...data}
  }

  getAxisConfig() {
    const superAxisConig = super.getAxisConfig()
    const axis = {
      rotated: true,
      x: {
        type: "category",
        tick: {
          format: (x, catName) => this.config.names[catName]
        }
      },
    }
    return {...superAxisConig, ...axis}
  }

  getConfig() {
    const superConfig = super.getConfig()
    const classThis = this
    const config = {
      bar: {},
      size: {
        width: $(this.selector).width(),
        height: 400,
      },
      padding: {
        left: 100,
        top: 0,
        right: 0,
        bottom: 0
      },
      grid: {
        y: {
          show: false
        }
      },
      onrendered: function() {
        const chart = this
        const selector = this.config().bindto
        const texts = d3.selectAll(`${selector} .bb-chart-text`)
        const countLabels = d3.selectAll(`${selector} text.bb-text`)
        countLabels.style('fill', '#000000')
        countLabels.each(function(d) {
          if(d.id === 'returned') {
            const total = chart.data().find((n) => n.id === 'total').values[d.index]
            d3.select(this).text(d3.format('.0%')(d.value/total.value))
          }
        })
        const scale = this.internal.scale
        const labelDirection = (ele, d) => {
          const containerBox = d3.select(`${selector} .bb-chart`).node().getBBox()
          const x = scale.y(d.value)
          const diff = containerBox.width - x
          const textBox = d3.select(ele).node().getBBox()
          return diff < textBox.width+4 ? 'left' : 'right'
        }
        texts.selectAll('.bb-custom-label')
          .data((d) => d.values)
          .join('text')
          .attr('class', 'bb-custom-label')
          .text((d) => classThis.names[d.id])
          .attr('y', function(d) {
            const bar = d3.select(`${selector} .bb-bars-${d.id} .bb-bar-${d.index}`)
            const barBox = bar.node().getBBox()
            const number = d3.select(`${selector} .bb-texts-${d.id} .bb-text-${d.index}`)
            const half = barBox.height/2
            number.attr('y', d.id != 'total' ? scale.x(d.x)+half : scale.x(d.x)-half)
            return d.id != 'total' ? scale.x(d.x)+half : scale.x(d.x)-half
          })
          .attr('x', function(d) {
            const x = scale.y(d.value)
            const number = d3.select(`${selector} .bb-texts-${d.id} .bb-text-${d.index}`)
            const padding = number.attr('x')-x
            return labelDirection(this, d) === 'left' ? x-padding : x+padding
          })
          .attr('text-anchor', function(d) {
            return labelDirection(this, d) === 'left' ? 'end' : 'start'
          })
          .attr('fill', function(d) {
            return labelDirection(this, d) === 'left' ? '#fff' : '#000'
          })
          .attr('transform', 'translate(0, 16)')
          .style('font-size', '14px')
          .style('font-weight', 'normal')
      }
    }
    return {...superConfig, ...config}
  }

}