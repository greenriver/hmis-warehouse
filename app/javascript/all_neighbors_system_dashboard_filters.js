class AllNeighborsSystemDashboardFilters {

  constructor(filters, charts, filterLabels) {
    this.initFilters(filters)
    this.initState(filters)
    this.filterLabels = filterLabels || []
    this.updateLabels()
    this.initCharts(charts)
    this.initResize()
    this.initTabChange()
  }

  test() {
    console.log(this)
  }

  initTabChange() {
    $('.all-neighbors__all__tabs a[data-toggle="tab"]').on('shown.bs.tab', () => {
      this.redrawCharts()
    })
  }

  initResize() {
    const debounce = (func, timeout = 300) => {
      let timer;
      return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => { func.apply(this, args); }, timeout);
      };
    }
    window.addEventListener('resize', debounce(this.redrawCharts))
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
        let startDp = this.filters[filter.name].start.datepicker('getDate')
        startDp = new Date(startDp.getFullYear(), startDp.getMonth(), 1);
        let endDp = this.filters[filter.name].end.datepicker('getDate')
        endDp = new Date(endDp.getFullYear(), endDp.getMonth() + 1, 0);
        this.state[filter.name] = [
          Date.parse(startDp),
          Date.parse(endDp)
        ]
      }
      if(filter.type === 'quarterRange') {
        const s = this.filters[filter.name].start.find('option:selected').val()
        const e = this.filters[filter.name].end.find('option:selected').val()
        this.state[filter.name] = [s, e]
        this.state.quarterData = filter.data
        this.setQuarterDateRange()
      }
    })
  }

  setQuarterDateRange() {
    if(this.state.quarterRange) {
      const [s, e] = this.state.quarterRange
      const startQ = this.state.quarterData.find((d) => d.name === s).range[0]
      const endQ = this.state.quarterData.find((d) => d.name === e).range[1]
      this.state.dateRange = [startQ, endQ].map((d) => {
        const [year, month, date] = d.split('-')
        return Date.parse(new Date(year, month-1, date))
      })
    }
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
      if(filter.type === 'quarterRange') {
        this.filters[filter.name] = {
          range: $(filter.selector),
          start: this.getDateElement($(filter.selector), 'start-date'),
          end: this.getDateElement($(filter.selector), 'end-date')
        }
        const startQ = filter.data.find((f) => f.name === this.filters[filter.name].start.val())
        const endQ = filter.data.find((f) => f.name === this.filters[filter.name].end.val())
        const startDate = this.dateFromString(startQ.range[0])
        const endDate = this.dateFromString(endQ.range[1])
        this.filters[filter.name].start.on('change', (e) => {
          const dataNames = filter.data.map((d) => d.name)
          const value = $(e.target).find('option:selected').val()
          const newValueIndex = dataNames.indexOf(value)
          const newOptions = dataNames.filter((d, i) => i >= newValueIndex).map((d) => {
            if(this.state[filter.name][1] === d) {
              return `<option value="${d}" selected="selected">${d}</option>`
            }
            return `<option value="${d}">${d}</option>`
          })
          this.state[filter.name][0] = value
          this.filters[filter.name].end.html(newOptions)
          this.redrawCharts()
        })

        this.filters[filter.name].end.on('change', (e) => {
          const dataNames = filter.data.map((d) => d.name)
          const value = $(e.target).find('option:selected').val()
          const newValueIndex = dataNames.indexOf(value)
          const newOptions = dataNames.filter((d, i) => i <= newValueIndex).map((d) => {
            if(this.state[filter.name][0] === d) {
              return `<option value="${d}" selected="selected">${d}</option>`
            }
            return `<option value="${d}">${d}</option>`
          })
          this.state[filter.name][1] = value
          this.filters[filter.name].start.html(newOptions)
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

  dateFromString(string) {
    const [year, month, date] = string.split('-')
    return new Date(year, month-1, date)
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
      } else if(label.name === 'cohortYears') {
        const text = this.state['cohort'].replace('after housing', '').replace('of housing', '')
        $(label.selector).text(text)
      } else if (label.name === 'quarterRange') {
        const text = this.state.quarterRange.join(' - ')
        $(label.selector).text(text)
      } else {
        // FIXME: not changing racial composition label when choosing Homelessness Status
        // console.log(this.state, label.selector, label.name)
        $(label.selector).text(this.state[label.name])
      }
    })
  }

  redrawCharts() {
    this.updateLabels()
    this.setQuarterDateRange()
    this.charts.forEach((chart) => {
      chart.redraw(this.state)
    })
  }
}
globalThis.AllNeighborsSystemDashboardFilters = AllNeighborsSystemDashboardFilters;
