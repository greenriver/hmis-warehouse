class AllNeighborsSystemDashboardBar {
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
        format: (v, id, i, text) => d3.format(',')(v)
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
          format: (y) => d3.format(',')(y)
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
        width: {
          ratio: 1,
        }
      },
      grid: {
        y: {show: true}
      },
      axis: this.getAxisConfig(),
      legend: {
        show: false,
      },
      bindto: this.selector,
      tooltip: {
        contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
          const labels = {
            exited: 'Exited to permanent destination',
            returned: 'Returned to homelessness in 1 year'
          }
          const index = d[0].index
          const title = this.config.keys[index]
          const swatches = d.map((n) => {
            const swatch = `<svg class="chart-legend-item-swatch-prs1 mb-2" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${this.config.colors[n.id][n.index]}"/></svg>`;
            const swatchLabel = `<div class="d-flex justify-content-start align-items-center"><div style="width:20px;padding-right:10px;">${swatch}</div><div class="pl-2">${labels[n.name]}</div></div>`;
            return `<tr><td>${swatchLabel}</td><td>${d3.format(',')(n.value)}</td></tr>`
          })
          let html = "<table class='bb-tooltip'>"
          html += "<thead>"
          html += `<tr><th colspan="2">${title}</th></tr>`
          html += "</thead>"
          html += "<tbody>"
          html += swatches.join('')
          html += `<tr><td>Rate of Return</td><td>${d3.format('.1%')(d[1].value/d[0].value)}</td></tr>`
          html += "</tbody>"
          html += "</table>"
          return html
        }
      },
      onrendered: function() {
        const selector = this.internal.config.bindto
        const data = this.data()
        if(data && data[0] && data[0].values) {
          const percentages = data[0].values.map((d, i) => {
            const returned = data[1].values[i]
            return returned.value/d.value
          })
        } else {
          const percentages = []
        }

        data.forEach((d, i) => {
          const barGroup = d3.select(`${selector} .bb-bars-${d.id}`)
          barGroup.attr('transform', i === 0 ? 'translate(15, 0)' : 'translate(-15, 0)')
          const textGroup = d3.select(`${selector} .bb-texts-${d.id}`)
          textGroup.attr('transform', i === 0 ? 'translate(15, 0)' : 'translate(-15, 0)')
          textGroup.selectAll('text').attr('text-anchor', i === 0 ? 'start' : 'end')
          const bar = barGroup.select(`.bb-bar-${i}`)
          // FIXME: if we only have one bar, billboard gets confused, ignore it for now
          if(bar.length > 0) {
            const barBox = bar.node().getBBox()
            const text = textGroup.selectAll('text')
            text.attr('transform', i === 0 ? `translate(${barBox.width/2*-1}, -20)` : `translate(${barBox.width/2}, -20)`)
            const xYears = this.internal.config.data_columns[0].slice(1)
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
          }
        })
      }
    }
  }

  test() {
    console.debug(this)
  }

  redraw(state) {
    this.state = state || {}
    this.init()
    this.chart.destroy()
    this.draw()
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}

class AllNeighborsSystemDashboardHorizontalBar extends AllNeighborsSystemDashboardBar {
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

  // redraw(state) {
  //   this.state = state
  //   this.init()
  //   this.chart.load({
  //     columns: this.getColumns(),
  //   })
  // }

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
    const axiswidth = 100
    const config = {
      bar: {},
      size: {
        width: $(this.selector).width(),
        height: 400,
      },
      padding: {
        left: axiswidth,
        top: 0,
        right: 0,
        bottom: 0
      },
      grid: {
        y: {
          show: false
        }
      },
      tooltip: {},
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
        const labelDirection = function(ele, d) {
          const containerBox = {width: $(`${selector}`).width()-axiswidth}
          const barBox = d3.select(`${selector} .bb-shapes-${d.id} .bb-shape-${d.index}`).node().getBBox()
          const textBox = d3.select(ele).node().getBBox()
          return barBox.width+textBox.width+4 >= containerBox.width ? 'left' : 'right'
        }
        texts.selectAll('.bb-custom-label')
          .data((d) => d.values)
          .join('text')
          .attr('class', 'bb-custom-label')
          .text((d) => classThis.names[d.id])
          .style('font-size', '14px')
          .style('font-weight', 'normal')

        texts.selectAll('.bb-custom-label')
          .attr('text-anchor', function(d) {
            return labelDirection(this, d) === 'left' ? 'end' : 'start'
          })
          .attr('x', function(d) {
            const x = scale.y(d.value)
            const number = d3.select(`${selector} .bb-texts-${d.id} .bb-text-${d.index}`)
            const padding = number.attr('x')-x
            return labelDirection(this, d) === 'left' ? x-padding : x+padding
          })
          .attr('y', function(d) {
            const bar = d3.select(`${selector} .bb-bars-${d.id} .bb-bar-${d.index}`)
            const barBox = bar.node().getBBox()
            const number = d3.select(`${selector} .bb-texts-${d.id} .bb-text-${d.index}`)
            const half = barBox.height/2
            number.attr('y', d.id != 'total' ? scale.x(d.x)+half : scale.x(d.x)-half)
            return d.id != 'total' ? scale.x(d.x)+half : scale.x(d.x)-half
          })
          .attr('fill', function(d) {
            return labelDirection(this, d) === 'left' ? '#fff' : '#000'
          })
          .attr('transform', 'translate(0, 16)')

      }
    }
    return {...superConfig, ...config}
  }
}
globalThis.AllNeighborsSystemDashboardBar = AllNeighborsSystemDashboardBar;
globalThis.AllNeighborsSystemDashboardHorizontalBar = AllNeighborsSystemDashboardHorizontalBar;
