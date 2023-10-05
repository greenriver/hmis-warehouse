class AllNeighborsSystemDashboarBar {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
  }

  init() {
    this.series = (this.data.series || []).filter((d) => !d.table_only)
    this.config = this.data.config
  }

  getConfig() {
    return {
      size: {
        width: $(this.selector).width(),
        height: 500,
      },
      data: {
        x: "x",
        columns: [
          ["x"].concat(this.config.keys)
        ].concat(this.series.map((d) => [d.name].concat(d.values))),
        types: {
          exited: "bar",
          returned: "bar",
        },
        colors: {
          exited: (d) => this.config.colors[d.id][d.index],
          returned: (d) => this.config.colors[d.id][d.index],
        },
        labels: {
          centered: false,
          show: true,
          color: '#000000',
          format: (v, id, i, j) => {
            return d3.format(",")(v);
          },
        },
      },
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
      axis: {
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
      },
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

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}
