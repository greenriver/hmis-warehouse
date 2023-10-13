class AllNeighborsSystemDashboardStack {
  constructor(data, initialState, selector, options) {
    this.data = data
    this.state = initialState
    this.selector = selector
    this.options = options
    this.init()
    this.padding = {
      left: 200,
      top: 0,
      right: 0,
      bottom: 0,
    }
  }

  init() {
    this.project = (this.data.project_types || []).filter((d) => d.project_type === this.state.projectType)[0] || {}
    this.homelessnessStatus = (this.data.homelessness_statuses || []).filter((d) => d.homelessness_status === this.state.homelessnessStatus)[0] || {}
    this.countLevel = (this.project.count_levels || []).filter((d) => d.count_level === this.state.countLevel)[0] || {}
    this.cohort = (this.countLevel.cohorts || []).filter((d) => d.cohort === this.state.cohort)[0] || {}
    this.householdType = (this.project.household_types || []).filter((d) => d.household_type === this.state.householdType)[0] || {}
    this.demographic = (this.householdType.demographics || this.data.demographics || []).filter((d) => d.demographic === this.state.demographics)[0] || {}
    this.config = this.project.config || this.homelessnessStatus.config || this.demographic.config || this.cohort.config || this.data.config || {}
    this.series = this.cohort.series || this.homelessnessStatus.series || this.demographic.series || this.countLevel.series || this.data.series || []
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

  getColumn(name) {
    let col = [name]
    if(name === 'x') {
      return col.concat(this.series.map((d) => d.name))
    } else {
      const index = this.config.keys.indexOf(name)
      this.series.forEach((d) => {
        const total = d.series.filter((n) => {
          if(this.state.dateRange) {
            return this.inDateRange(n.date, this.state.dateRange)
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

  getDataConfig() {
    return {
      x: "x",
      order: null,
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
        format: (v, id, i, j) => {
          return d3.format(",")(v);
        },
      },
      stack: {
        normalize: true,
      }
    }
  }

  getAxisConfig() {
    return {
      rotated: true,
      x: {
        type: "category",
        tick: {
          width: this.padding.left,
        }
      },
      y: {
        show: false,
      }
    }
  }

  getConfig() {
    //Default config, see subclasses below for custom config
    const normalizeDataLabels = this.normalizeDataLabels
    const fitLabels = this.fitLabels
    const config = {
      size: {
        width: $(this.selector).width(),
        height: this.series.length * 90,
      },
      data: this.getDataConfig(),
      axis: this.getAxisConfig(),
      padding: this.padding,
      bar: {
        width: 50,
      },
      bindto: this.selector,
      legend: {show: false},
      onrendered: function() {
        normalizeDataLabels(this)
        fitLabels(this)
      }
    }
    if(this.options.legend) {
      config.legend = this.getColumnLegend(this.options.legend.selector)
    }
    return config
  }

  getColumnLegend(bindto) {
    return {
      contents: {
        bindto: bindto,
        template: (title, color) => {
          const swatch = `<svg class="mt-1 chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
          return `<div class="col-xs-12 col-md-3 mb-4 d-flex">${swatch}<div class="chart-legend-item-label-prs1">${this.config.names[title]}</div></div>`;
        },
      },
    }
  }

  getSimpleLegend(bindto) {
    return {
      contents: {
        bindto: bindto,
        template: (title, color) => {
          const swatch = `<svg class="mt-1 chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
          return `<div class="d-flex pr-4">${swatch}<div class="chart-legend-item-label-prs1">${this.config.names[title]}</div></div>`;
        },
      },
    }
  }

  fitLabels(chart) {
    const selector = chart.internal.config.bindto
    chart.data().forEach((d) => {
      d.values.forEach((v, i) => {
        const text = $(`${selector} .bb-texts-${d.id.replaceAll('_', '-')} .bb-text-${v.x}`)
        const textBox = text[0].getBBox()
        const bar = $(`${selector} .bb-bars-${d.id.replaceAll('_', '-')} .bb-bar-${v.x}`)
        const barBox = bar[0].getBBox()
        if(textBox.width >= barBox.width || textBox.height >= barBox.height) {
          text.text('')
        }
      })
    })
  }

  normalizeDataLabels(chart) {
    // is there a better way to do this with billboard config?
    const selector = chart.internal.config.bindto
    chart.data().forEach((d) => {
      d.values.forEach((v) => {
        const text = $(`${selector} .bb-texts-${d.id.replaceAll('_', '-')} .bb-text-${v.x}`)
        text.text(d3.format(".0%")(v.ratio))
      })
    })
  }

  drawTotals(chart) {
    const sums = chart.categories().map((cat, i) => {
      return d3.sum(chart.data().map((d) => {
        return d3.format('.0f')(d.values[i].value)
      }))
    })
    const selector = chart.internal.config.bindto
    let container = d3.select(`${selector} .bb-main`)
    return container.selectAll(`.bb-text__custom-total`)
      .data(sums)
      .join(
        (enter) => enter.append('text').attr('class', 'bb-text__custom-total'),
        (update) => update,
        (exit) => exit.remove()
      )
  }

  redraw(state) {
    this.state = state
    this.init()
    this.chart.destroy()
    this.draw()
  }

  draw() {
    this.chart = bb.generate(this.getConfig())
  }
}

// Unhoused Pop vertical stack + internal returns to homelessness vertical stack
class AllNeighborsSystemDashboardUPVerticalStack extends AllNeighborsSystemDashboardStack {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
    this.padding = {}
  }

  getDataConfig() {
    const superDataConfig = super.getDataConfig()
    const data = {
      stack: {
        normalize: false
      }
    }
    return {...superDataConfig, ...data}
  }

  getAxisConfig() {
    const superAxisConfig = super.getAxisConfig()
    const axis = {
      rotated: false,
      y: {
        show: true,
        tick: {
          format: d3.format(',')
        }
      }
    }
    return {...superAxisConfig, ...axis}
  }

  getConfig() {
    const fitLabels = this.fitLabels
    const superConfig = super.getConfig()
    const config = {
      size: {
        width: $(this.selector).width(),
        height: 400,
      },
      data: this.getDataConfig(),
      axis: this.getAxisConfig(),
      grid: {
        y: {show: true}
      },
      // bar: {
      //   width: 84,
      // },
      padding: this.padding,
      onrendered: function() {
        fitLabels(this)
      }
    }
    if(this.options.legend) {
      config.legend = this.getSimpleLegend(this.options.legend.selector)
    }
    return {...superConfig, ...config}
  }
}


// Time To Obtain Housing stacked bar
class AllNeighborsSystemDashboardTTOHStack extends AllNeighborsSystemDashboardStack {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
    this.padding = {
      left: 300,
      top: 0,
      right: 0,
      bottom: 0,
    }
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
            return this.inDateRange(n.date, this.state.dateRange)
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
        
        col.push(d3.mean(total))
      })
      return col
    }
  }

  getDataConfig() {
    const superDataConfig = super.getDataConfig()
    const data = {
      stack: {
        normalize: false
      },
      labels: {
        show: true,
        centered: true,
        colors: this.config.label_colors,
        format: (v, id, i, texts) => d3.format('.0f')(v),
      }
    }
    return {...superDataConfig, ...data}
  }

  getAxisConfig() {
    const superAxisConfig = super.getAxisConfig()
    const x = {
      tick: {
        width: this.padding.left,
        text: {
          position: {x: -40, y: 3},
        },
      }
    }
    const y = {show: true}
    const axis = {
      x: {...superAxisConfig.x, ...x},
      y: {...superAxisConfig.y, ...y}
    }
    return {...superAxisConfig, ...axis}
  }

  getConfig() {
    const fitLabels = this.fitLabels
    const superConfig = super.getConfig()
    const superDrawTotals = super.drawTotals
    const padding = this.padding
    const config = {
      data: this.getDataConfig(),
      axis: this.getAxisConfig(),
      grid: {
        x: {show: true}
      },
      padding: padding,
      onrendered: function() {
        const selector = this.internal.config.bindto
        $(`${selector} .bb-axis-x .tick line`).attr('x2', padding.left*-1)
        superDrawTotals(this)
          .text((d) => d)
          .attr('x', (d) => this.internal.scale.y(d))
          .attr('y', (d, i) => this.internal.scale.x(i))
          .attr('transform', 'translate(30, 6)')
        fitLabels(this)
      }
    }
    if(this.options.legend) {
      config.legend = this.getSimpleLegend(this.options.legend.selector)
    }
    return {...superConfig, ...config}
  }
}

// Returns to homelessness group stack with label on the left
class AllNeighborsSystemDashboardRTHStack extends AllNeighborsSystemDashboardStack {
  constructor(data, initialState, selector, options) {
    super(data, initialState, selector, options)
  }

  getConfig() {
    const fitLabels = this.fitLabels
    const superConfig = super.getConfig()
    const superNormalizeDataLabels = super.normalizeDataLabels
    const data = this.data
    const demographic = this.demographic
    const config = {
      padding: {
        left: 150,
        top: 0,
        right: 200,
        bottom: 0,
      },
      onrendered: function() {
        superNormalizeDataLabels(this)
        const selector = this.internal.config.bindto
        let container = d3.select(`${selector} .bb-main`)
        container.selectAll(`.bb-text__custom-total`)
          .data([demographic.exited_household_count, demographic.returned_household_count])
          .join(
            (enter) => enter.append('text').attr('class', 'bb-text__custom-total'),
            (update) => update,
            (exit) => exit.remove()
          )
          .text((d) => `${d3.format(',')(d)} Households`)
          .attr('x', (d) => this.internal.scale.y(100))
          .attr('y', (d, i) => this.internal.scale.x(i))
          .attr('transform', 'translate(30, 6)')
        fitLabels(this)
      }
    }
    if(this.options.legend) {
      config.legend = this.getColumnLegend(this.options.legend.selector)
    }
    return {...superConfig, ...config}
  }
}
