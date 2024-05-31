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
    this.householdType = (this.projectType.household_types || []).filter((d) => d.household_type === this.state.householdType)[0] || {}
    this.demographic = (this.householdType.demographics || []).filter((d) => d.demographic === this.state.demographics)[0] || {}
    this.series = this.countLevel.series || this.demographic.series || []
    this.uniqueCounts = this.countLevel.unique_counts
    this.monthlyCounts = this.countLevel.monthly_counts // array of [date, new placements]
    this.config = this.projectType.config || {}
    this.quarters = this.data.quarters || []
  }

  test() {
    console.debug(this)
  }

  inDateRange(dateString, range) {
    const [year, month, day] = dateString.split('-')
    //ruby date month is 1 based while js date month is 0
    if(range && range.length === 2) {
      const date = Date.parse(new Date(year, month-1, day))
      const [s, e] = range
      return date >= s && date <= e
    }
    return false
  }

  getMonthlyTotals() {
    if(!this.monthlyCounts || !this.monthlyCounts[0]) {
      return []
    }
    return this.monthlyCounts[0].filter((d) => {
      return this.inDateRange(d[0], this.state.dateRange)
    }).map((d) => d[1])
  }

  // monthly counts, limited to the state of the filter
  visibleMonths() {
    return this.monthlyCounts[0].filter((d) => {
      return this.inDateRange(d[0], this.state.dateRange)
    })
  }

  // sum up previous visible months
  getTotalCounts(index) {
    return d3.sum(this.visibleMonths().slice(0, index).map((d) => d[1]))
  }

  // Removed until further notice
  // getUniqueCounts() {
  //   return this.uniqueCounts[0].filter((d) => {
  //     return this.inDateRange(d[0], this.state.dateRange)
  //   }).map((d) => d[1])
  // }

  getColumns() {
    let xCols = ['x']
    let keyCols = (this.config.keys || []).map((key, i) => {
      let cols = [key]
      let totalCounts = 0
      this.visibleMonths().forEach((d) => {
        const [x, y] = d
        if(xCols.indexOf(x) === -1) {
          xCols.push(x)
        }
        // Sum visible new placements
        totalCounts += y
        cols.push(totalCounts)
      })
      return cols
    })
    return [xCols].concat(keyCols)
  }

  getDataConfig() {
    return {
      x: "x",
      columns: this.getColumns(),
      type: 'line',
      colors: this.config.colors,
      names: this.config.names,
    }
  }

  getAxisConfig() {
    return {
      y: {
        min: 0,
        padding: {
          bottom: 0,
          top: 20,
        },
      },
      x: {
        type: "timeseries",
        tick: {
          format: this.xAxisFormat.bind(this),
        },
        clipPath: false,
      }
    }
  }

  getConfig(names) {
    return {
      data: this.getDataConfig(),
      grid: {
        y: {
          show: true
        }
      },
      padding: {
        left: 50,
        top: 10,
        right: 25,
        bottom:0,
      },
      axis: this.getAxisConfig(),
      legend: {
        contents: {
          bindto: this.options.legend.selector,
          template: (title, color) => {
            let swatch = `<svg class="mt-1 chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
            if(this.config.shapes) {
              const shape = this.config.shapes[title]
              if(shape === 'circle') {
                swatch = `<svg class="mt-1 chart-legend-item-swatch-prs1" viewBox="0 0 12 12" xmlns="http://www.w3.org/2000/svg"><circle cx="6" cy="6" r="5" fill="${color}"/></svg>`;
              }
              if(shape === 'triangle') {
                swatch = `<svg class="mt-1 chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><polygon points="5,0 10,10 0,10" fill="${color}"/></svg>`;
              }
            }
            return `<div class="d-flex pr-4">${swatch}<div class="chart-legend-item-label-prs1">${this.config.names[title]}</div></div>`;
          },
        },
      },
      tooltip: {
        contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
          const index = d[0].index
          const monthlyCount = this.getMonthlyTotals()[index]
          if (typeof monthlyCount !== 'undefined') {
            let html = "<table class='bb-tooltip'>"
            html += "<thead>"
            html += `<tr><th colspan='3'>${defaultTitleFormat(d[0].x)}</th></tr>`
            html += "</thead>"
            html += "<tbody>"
            html += `<tr><td>New Placements (${this.countLevel.count_level})</td><td>${d3.format(',')(monthlyCount)}</td></tr>`
            html += `<tr><td>Total Placements (${this.countLevel.count_level})</td><td>${d3.format(',')(d[0].value)}</td></tr>`
            // html += `<tr><td>Unique  ${this.countLevel.count_level} Housed to Date</td><td>${d3.format(',')(uniqueCount)}</td></tr>`
            html += "</tbody>"
            html += "</table>"
            return html
          }
        },
      },
      bindto: this.selector
    }
  }

  xAxisFormat(d) {
    return d.toLocaleDateString('en-us', {year: 'numeric', month: 'short'})
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.destroy()
    this.draw()
  }

  drawInsights() {
    //placeholder some charts won't have this
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
    this.drawInsights()
  }
}

//internal scatter
class AllNeighborsSystemDashboardScatter extends AllNeighborsSystemDashboardLine {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
  }

  getProgramNames(id, index) {
    let name = 'Unknown'
    const keyIndex = (this.config.keys || []).indexOf(id)
    if(keyIndex > -1) {
      const series = this.series[keyIndex] || []
      if(series.length > 0) {
        name = series.filter((d) => this.inDateRange(d[0], this.state.dateRange))[index][3] || 'Unknown'
      }
    }
    return name
  }

  getColumns() {
    let allCols = []
    let keyCols = (this.config.keys || []).forEach((key, i) => {
      const series = this.series[i] || []
      if(series.length > 0) {
        let cols = [key]
        let xCols = [`${key}_x`];
        series.forEach((d) => {
          const inRange = this.inDateRange(d[0], this.state.dateRange)
          if(inRange) {
            const [w, x, y] = d
            xCols.push(x)
            cols.push(y)
          }
        })
        allCols.push(xCols)
        allCols.push(cols)
      }
    })
    return allCols
  }

  getDataConfig() {
    let xs = {};
    let dataTypes = {};
    (this.config.keys || []).forEach((key) => {
      xs[key] = `${key}_x`
    })

    return {
      xs: xs,
      columns: this.getColumns(),
      type: 'scatter',
      colors: this.config.colors,
      names: this.config.names,
    }
  }

  stylePoints(point) {
    const shape = d3.select(point)
    const fill = shape.style('fill')
    const color = d3.rgb(fill)
    color.opacity = 0.5
    shape.style('fill', color.toString())
    shape.style('stroke', d3.rgb(fill).toString())
  }

  getConfig() {
    const classOptions = this.options
    const classConfig = this.config
    const styleShapes = this.stylePoints
    const config = {
      padding: {
        right: 20,
      },
      axis: {
        x: {
          min: 0,
          padding: {
            left: 20,
            right: 20,
            unit: 'px',
          },
          tick: {
            fit: false
          },
          label: {
            text: 'Number of Households Moved-In',
            position: 'outer-center',
          }
        },
        y: {
          min: 0,
          padding: {
            bottom: 0,
            top: 20,
          },
          label: {
            text: 'Average Days',
            position: 'outer-middle',
          }
        }
      },
      grid: {
        y: {
          show: false,
        },
      },
      point: {
        opacity: 1,
        r: 9,
        pattern: this.config.keys.map((key) => {
          const shape = this.config.shapes[key]
          if(shape === 'triangle') {
            return "<polygon points='7.5,0 0,15 15,15'></polygon>"
          } else {
            return shape || 'circle'
          }
        })
      },
      tooltip: {
        contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
          let html = "<table class='bb-tooltip'>"
          html += "<thead>"
          html += `<tr><th colspan='2'>${this.getProgramNames(d[0].id, d[0].index)}</th></tr>`
          html += "</thead>"
          html += "<tbody>"
          html += `<tr><td>Housed Households</td><td>${d[0].x}</td></tr>`
          html += `<tr><td>Average Days Referral to Housing</td><td>${d[0].value}</td></tr>`
          html += "</tbody>"
          html += "</table>"
          return html
        },
      },
      onrendered: function() {
        const selector = this.internal.config.bindto
        // total move in label
        let totals = d3.sum(this.data(), (d) => d3.sum(d.values, (n) => n.x))
        $(`${classOptions.total.selector}`).text(d3.format(',')(totals))
        // average day line and text
        const chartEleId = d3.select(selector).attr('id')
        let mean = d3.mean(this.data().map((d) => d.values.map((n) => n.value)).flat())
        const scale = this.internal.scale
        const container = d3.select(`${selector} .bb-chart-circles`)
        container.selectAll(`line.${chartEleId}__mean`)
          .data([mean])
          .join('line')
            .attr('class', `${chartEleId}__mean`)
            .attr('x1', 0)
            .attr('y1', (d) => scale.y(d))
            .attr('x2', scale.x(scale.x.domain()[1]))
            .attr('y2', (d) => scale.y(d))
            .style('stroke', 'rgba(0, 0, 0, 0.38)')

        container.selectAll(`text.${chartEleId}__mean-label`)
          .data([mean])
          .join('text')
            .attr('class', `${chartEleId}__mean-label`)
            .attr('text-anchor', 'end')
            .attr('x', scale.x(scale.x.domain()[1]))
            .attr('y', (d) => scale.y(d)-10)
            .attr('stroke-width', '2px')
            .text((d) => {
              return `Overall Average: ${d3.format('.0f')(d)} Days`
            })

        // shapes with opacity fill and stroke
        const shapes = d3.selectAll(`${selector} .bb-shape`)
        shapes.each(function(d) {
          styleShapes(this)
        })
        const legendItems = d3.selectAll(`${classOptions.legend.selector} .bb-legend-item svg :first-child`)
        legendItems.each(function(d) {
          styleShapes(this)
        })


      }
    }
    return {...super.getConfig(), ...config}
  }

  drawInsights() {
    //TODO: This will update when the filters/charts update
    if(this.options.insights) {
      const insights = $(this.options.insights.selector)
      let html = '<ul>'
      html += '<li>TODO insights data for</li>'
      Object.keys(this.state).forEach((key) => {
        html += `<li><strong>${key}:</strong> ${this.state[key]}</li>`
      })
      insights.html(html)
    }
  }

}

//internal line + bar -- Housing Placement
class AllNeighborsSystemDashboardLineBarByQuarter extends AllNeighborsSystemDashboardLine {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
  }

  init() {
    super.init()
    this.config.names.Placements_per_Quarter = "Placements per Quarter"
    this.programName = (this.countLevel.program_names || []).filter((d) => d.program_name === this.state.programName)[0] || {}
    this.population = (this.programName.populations || []).filter((d) => d.population === this.state.population)[0] || {}
    this.countType = (this.population.count_types || []).filter((d) => d.count_type === this.state.countType)[0] || {}

    this.series = this.countType.series || []
    this.monthlyCounts = this.countType.monthly_counts || []
    this.breakdownCounts = this.countType.breakdown_counts || []
  }

  getBreakdowns() {
    if(!this.breakdownCounts || !this.breakdownCounts[0]) {
      return []
    }
    return this.breakdownCounts[0].filter((d) => {
      return this.inDateRange(d[0], this.state.dateRange)
    }).map((d) => d[1])
  }

  xAxisFormat(d) {
    const quarter = this.quarters.find((q) => {
      const [s, e] = q.range.map((r) => {
        const [year, month, day] = r.split('-')
        return new Date(year, month-1, day)
      })
      return d >= s && d <= e
    })
    return quarter ? quarter.name : d.toLocaleDateString('en-us', {year: 'numeric', month: 'short'})
  }

  getBarColumns() {
    let barCol = ['Placements_per_Quarter']
    this.monthlyCounts[0].forEach((d) => {
      const inRange = this.inDateRange(d[0], this.state.dateRange)
      if(inRange) {
        const [x, y] = d
        barCol.push(y)
      }
    })
    return barCol
  }

  getAxisConfig() {
    const superAxis = super.getAxisConfig()
    return {
      ...superAxis,
      y: {
        ...superAxis.y,
        label: {
          text: "Placements per Quarter",
          position: "outer-middle"
        }
      },
      y2: {
        ...superAxis.y,
        show: true,
        label: {
          text: "Total Placements",
          position: "outer-middle"
        }
      }
    }
  }

  getDataConfig() {
    const superData = super.getDataConfig()
    const columns = [...superData.columns].concat([this.getBarColumns()])
    return {
      ...superData,
      axes: {
        "Total_Placements": "y2",
        "Placements_per_Quarter": "y",
      },
      columns: columns,
      type: null,
      types: {
        "Total_Placements": 'line',
        "Placements_per_Quarter": 'bar',
      },
      grid: {
        y: {show: true},
        y2: {show: true},
      },
      colors: {...superData.colors, "Placements_per_Quarter": "#97B9BD"},
    }
  }

  getConfig() {
    const superConfig = super.getConfig()
    const config = {
      padding: {
        left: 75,
        top: 10,
        right: 75,
        bottom:0,
      },
      tooltip: {
        contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
          const index = d[0].index
          const breakdowns = this.getBreakdowns()[index]
          if(breakdowns) {
            let html = "<table class='bb-tooltip'>"
            html += "<thead>"
            html += `<tr><th colspan='2'>${defaultTitleFormat(d[0].x)}</th></tr>`
            html += "</thead>"
            html += "<tbody>"
            breakdowns.forEach((d) => {
              html+= `<tr><td>${d.label}</td><td>${d.value}</td></tr>`
            })
            html += "</tbody>"
            html += "</table>"
            return html
          }
        },
      },
    }
    return {...superConfig, ...config}
  }

  drawInsights() {
    //TODO: This will update when the filters/charts update
    if(this.options.insights) {
      const insights = $(this.options.insights.selector)
      let html = '<ul>'
      html += '<li>TODO insights data for</li>'
      Object.keys(this.state).forEach((key) => {
        html += `<li><strong>${key}:</strong> ${this.state[key]}</li>`
      })
      insights.html(html)
    }
  }

}

//internal scatter by quarter -- Time to obtain housing
class AllNeighborsSystemDashboardStackedLineByQuarter extends AllNeighborsSystemDashboardLine {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
  }

  getDataConfig() {
    return {...super.getDataConfig(), ...{type: 'scatter'}}
  }

  xAxisFormat(d) {
    const quarter = this.quarters.find((q) => {
      const [s, e] = q.range.map((r) => {
        const [year, month, day] = r.split('-')
        return new Date(year, month-1, day)
      })
      return d >= s && d <= e
    })
    return quarter ? quarter.name : d.toLocaleDateString('en-us', {year: 'numeric', month: 'short'})
  }

  getAxisConfig() {
    const superAxis = super.getAxisConfig()
    return {
      ...superAxis,
      y: {
        ...superAxis.y,
        tick: {
          stepSize: 50,
        },
        label: {
          text: "Average Days",
          position: "outer-middle"
        }
      },
    }
  }

  getConfig() {
    const dateToQuarterName = this.xAxisFormat.bind(this)
    const classConfig = this.config
    const config = {
      point: {
        opacity: 1,
        r: 7.5,
        pattern: Object.values(this.config.shapes).map((shape) => {
          if(shape === 'triangle') {
            return "<polygon points='7.5,0 0,15 15,15'></polygon>"
          } else {
            return shape
          }
        })
      },
      tooltip: {
        contents: function(d, defaultTitleFormat, defaultValueFormat, color) {
          const idNames = this.data.names()
          const dataGroup = this.data().map((n) => n.values[d[0].index])
          let html = "<table class='bb-tooltip'>"
          html += "<thead>"
          html += `<tr><th colspan='2'>Average Days</th></tr>`
          html += "</thead>"
          html += "<tbody>"
          html += `<tr><td colspan='2'>${dateToQuarterName(d[0].x)}</td></tr>`
          dataGroup.forEach((n) => {
            html += `<tr><td>${idNames[n.id]}</td><td>${n.value}</td></tr>`
          })
          html += "</tbody>"
          html += "</table>"
          return html
        },
      },
    }
    return {...super.getConfig(), ...config}
  }

  drawInsights() {
    //TODO: This will update when the filters/charts update
    if(this.options.insights) {
      const insights = $(this.options.insights.selector)
      let html = '<ul>'
      html += '<li>TODO insights data for</li>'
      Object.keys(this.state).forEach((key) => {
        html += `<li><strong>${key}:</strong> ${this.state[key]}</li>`
      })
      insights.html(html)
    }
  }

}
globalThis.AllNeighborsSystemDashboardLine = AllNeighborsSystemDashboardLine;
globalThis.AllNeighborsSystemDashboardScatter = AllNeighborsSystemDashboardScatter;
globalThis.AllNeighborsSystemDashboardLineBarByQuarter = AllNeighborsSystemDashboardLineBarByQuarter;
globalThis.AllNeighborsSystemDashboardScatter = AllNeighborsSystemDashboardScatter;
