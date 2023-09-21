class AllNeighborsSystemDashboardFilters {
  
  constructor(filters, charts, filterLabels) {
    this.initFilters(filters)
    this.initState(filters)
    this.filterLabels = filterLabels || []
    this.updateLabels()
    this.initCharts(charts)
  }

  test() {
    console.log(this)
  }

  initCharts(chartConfig) {
    this.charts = chartConfig.map((config) => {
      const chart = new config.chart(config.data, this.state, config.selector, config.options || {})
      chart.draw()
      return chart
    })
  }

  initState(filters) {
    this.state = {}
    filters.forEach((filter) => {
      if(filter.type === 'select' || filter.type === 'year') {
        this.state[filter.name] = this.filters[filter.name].val()
      }
      if(filter.type === 'dateRange') {
        const startDp = this.filters[filter.name].start.datepicker('getDate')
        this.state[filter.name] = [
          Date.parse(this.filters[filter.name].start.datepicker('getDate')),
          Date.parse(this.filters[filter.name].end.datepicker('getDate'))
        ]
      }
    })
  }

  initFilters(filters) {
    this.filters = {}
    filters.forEach((filter) => {
      if(filter.type === 'select' || filter.type === 'year') {
        this.filters[filter.name] = $(filter.selector)
        this.filters[filter.name].on('change', (e) => {
          this.state[filter.name] = $(e.target).val()
          this.redrawCharts()
        })
      }
      if(filter.type === 'dateRange') {
        this.filters[filter.name] = {
          range: $(filter.selector),
          start: this.getDateElement($(filter.selector), 'start-date'),
          end: this.getDateElement($(filter.selector), 'end-date')
        }
        const startDate = this.filters[filter.name].start.val()
        const endDate = this.filters[filter.name].end.val()
        const config = {
          format: 'M yyyy',
          startDate: startDate,
          endDate: endDate,
          startView: 'months',
          minViewMode: 'months'
        }

        this.filters[filter.name].range.each(function() {
          $(this).datepicker(config)
        })

        this.filters[filter.name].start.on('changeDate', (e) => {
          this.filters[filter.name].end.datepicker("setStartDate", e.date)
          this.state[filter.name][0] = e.date
          this.redrawCharts()
        })

        this.filters[filter.name].end.on('changeDate', (e) => {
          this.filters[filter.name].start.datepicker("setEndDate", e.date)
          this.state[filter.name][1] = e.date
          this.redrawCharts()
        })
      }
    })
  }

  getDateElement(selector, dateClass) {
    const node = selector.filter(function() {
      return $(this).hasClass(dateClass)
    })[0]
    return $(node)
  }

  updateLabels() {
    this.filterLabels.forEach((label) => {
      if(label.name === 'dateRange') {
        const dateStrings = this.state.dateRange.map((d) => new Date(d).toLocaleDateString('en-us', {year: 'numeric', month: 'short'}))
        $(label.selector).text(`${dateStrings[0]} - ${dateStrings[1]}`)
      } else {
        $(label.selector).text(this.state[label.name])
      }
    })
  }

  redrawCharts() {
    this.updateLabels()
    this.charts.forEach((chart) => {
      chart.redraw(this.state)
    })
  }
}