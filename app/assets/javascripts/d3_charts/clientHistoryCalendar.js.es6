class AppClientHistoryCalendar {
  constructor(data, eventsData, calendar_selector) {
    // console.log('ClientHistoryCalendar')
    // console.log('data', data)
    // console.log('eventsData', eventsData)
    // console.log('calendar_selector', calendar_selector)
    this.data = data
    this.container = d3.select(calendar_selector)
    this.eventsData = eventsData
  }

  getDateFromString(dateString) {
    var parts = dateString.split('-')
    return new Date(parts[0], parts[1] - 1, parts[2])
  }

  includesDate(dates, date) {
    return dates.includes(date)
  }

  prefixClass(grouping, item) {
    var cssClass = `client__calendar-${grouping}`
    if (item) {
      return `${cssClass}__${item}`
    }
    return cssClass
  }

  draw(filters) {
    // console.log('filters', filters)
    this.data.forEach((weekData, i) => {
      // console.log('weekData', weekData)

      var projectData = weekData.projects.map((p) => {
        var inProjectType = true
        var inProjectName = true
        var inContactType = true
        if (filters.projectTypes && filters.projectTypes.length > 0) {
          inProjectType = filters.projectTypes.includes(p.project_type)
        }
        if (filters.projects && filters.projects.length > 0) {
          inProjectName = filters.projects.includes(p.project_id)
        }
        if (filters.contactTypes && filters.contactTypes.length > 0) {
          filters.contactTypes.every((ct) => {
            inContactType = ct == 'extrapolation' ? p[ct] : p[ct] && p[ct].length > 0
            return !inContactType
          })
        }
        p.opacity = inProjectType && inProjectName && inContactType ? 1 : 0.2
        return p

      })

      var month = weekData.month
      var dayDomain = weekData.days

      var includesStart = (project) => { return this.includesDate(weekData.days, project.entry_date) }
      var includesEnd = (project) => { return this.includesDate(weekData.days, project.exit_date) }
      var barLeft = (d) => {
        var entryDate = dayScale(d.entry_date) >= 0 ? dayScale(d.entry_date) : 0
        if (includesStart(d)) {
          entryDate = entryDate + 1
        }
        return entryDate + '%'
      }

      var barWidth = (d) => {
        var entryDate = includesStart(d) ? dayScale(d.entry_date) : 0
        var exitDate = includesEnd(d) ? dayScale(d.exit_date) : 100
        if (includesEnd(d)) {
          exitDate = exitDate + dayScale.bandwidth()
        }
        var width = exitDate - entryDate >= 0 ? (exitDate - entryDate) : 0
        if (includesStart(d)) {
          width = width - 1
        }
        if (includesEnd(d)) {
          width = width - 1
        }
        return width + '%'
      }

      var dayScale = d3.scaleBand()
        .domain(dayDomain)
        .range([0, 100])

      var labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      var dayLabels = this.container.selectAll(`.${this.prefixClass('day-labels')}`)
        .data([labels])
        .enter()
        .append('div')
        .attr('class', this.prefixClass('day-labels'))

      dayLabels.selectAll(`.${this.prefixClass('day-label')}`)
        .data((d) => d)
        .enter()
        .append('div')
        .attr('class', this.prefixClass('day-label'))
        .style('width', dayScale.bandwidth() + '%')
        .text((d) => d)

      var week = this.container
        .selectAll(`.${this.prefixClass('week', `${i}`)}`)
        .data([weekData])
        .enter()
        .append('div')
        .attr('class', `${this.prefixClass('week', `${i}`)} ${this.prefixClass('week')}`)

      week = this.container
        .selectAll(`.${this.prefixClass('week', `${i}`)}`)

      var days = week.selectAll(`.${this.prefixClass('day')}`)
        .data(dayDomain)
        .enter()
        .append('div')
        .attr('class', (d) => this.prefixClass('day') + ' day-' + d)
        .style('left', (d, i) => (dayScale.bandwidth() * i) + '%')
        .style('width', dayScale.bandwidth() + '%')
        .append('span')
        .text((d) => this.getDateFromString(d).getDate())
        .attr('class', (d) => this.getDateFromString(d).getMonth() === (month - 1) ? this.prefixClass('date') : `${this.prefixClass('date')} ${this.prefixClass('date', 'previous-month')}`)

      var projectClass = this.prefixClass('project-container')
      var projects = week.selectAll(`.${projectClass}`)
        .data(projectData)
        .join(
          (enter) => {
            return enter.append('div')
              .attr('class', (d, i) => {
                return `${projectClass} ${projectClass}__${i}`
              }).style('opacity', (d) => d.opacity)
          },
          (update) => {
            return update.transition().style('opacity', (d) => d.opacity)
          },
          (exit) => {
            return exit.remove()
          }
        )

      var bars = projects.selectAll(`.${this.prefixClass('project')}`)
        .data((d) => [d])
        .enter()
        .append('div')
        .attr('class', (d) => {
          if (d.extrapolation_only) {
            var classes = [this.prefixClass('project')]
          } else {
            var classes = [this.prefixClass('project'), 'project-type-' + d.project_type]
          }

          if (includesStart(d)) {
            classes.push(this.prefixClass('project', 'has-start'))
          }
          if (includesEnd(d)) {
            classes.push(this.prefixClass('project', 'has-end'))
          }
          if (!d.bed_nights && !d.extrapolation && !d.current_situations && !d.move_in_dates && !d.service_dates && !d.ce_events && !d.custom_events) {
            classes.push(this.prefixClass('project', 'no-events'))
          }
          return classes.join(' ')
        })
        .style('margin-left', barLeft)
        .style('width', barWidth)

      var tooltipTriggers = projects.selectAll(`.${this.prefixClass('tooltip-trigger')}`)
        .data((d, i) => {
          d.index = i
          return [d]
        })
        .enter()
        .append('a')
        .attr('class', this.prefixClass('tooltip-trigger'))
        .attr('data-trigger-content', (d) => `#client__calendar-tooltip__${i}_${d.index}`)
        .attr('href', 'javascript:void(0)')
        .attr('tabindex', '0')
        .style('left', (d) => d.extrapolation_only ? barLeft(d.extrapolation) : barLeft(d))
        .style('top', 0)
        .style('bottom', 0)
        .style('width', (d) => d.extrapolation_only ? barWidth(d.extrapolation) : barWidth(d))

      tooltipTriggers.each(function (d, index) {
        $(this).popover({
          trigger: 'focus',
          content: $(`#client__calendar-tooltip__${i}_${d.index}`),
          title: '',
          placement: 'bottom',
          html: true,
        })
      })

      const extrapolationClass = this.prefixClass('project', 'extrapolation')
      projects.selectAll(`.${extrapolationClass}`)
        .data((d) => d.extrapolation ? [d] : [])
        .join(
          (enter) => {
            return enter.append('div')
              .attr('class', extrapolationClass)
              .style('left', (d) => barLeft(d.extrapolation))
              .style('width', (d) => barWidth(d.extrapolation))
              .append('i')
              .attr('class', (d) => includesEnd(d.extrapolation) ? 'icon-cross' : '')
          },
          (update) => {
            update.style('opacity', (d) => {
              if (filters.contactTypes && filters.contactTypes.length > 0) {
                return filters.contactTypes.includes('extrapolation') ? 1 : 0.2
              }
              return 1
            })
          },
          (exit) => {
            return exit.remove()
          }
        )

      bars.selectAll(`.${this.prefixClass('project', 'start')}`)
        .data((d) => includesStart(d) && !d.extrapolation_only ? [d] : [])
        .enter()
        .append('div')
        .attr('class', this.prefixClass('project', 'start'))

      bars.selectAll(`.${this.prefixClass('project', 'end')}`)
        .data((d) => {
          if(includesEnd(d)) {
            if (d.exit_date == new Date().toJSON().slice(0, 10)) {
              return []
            } else {
              return [d]
            }
          } else {
            return []
          }
        })
        .enter()
        .append('div')
        .attr('class', this.prefixClass('project', 'end'))

      const dayEventsClass = this.prefixClass('project', 'day-events')
      const dayEventsStartClass = this.prefixClass('project', 'day-events-has-start')

      var dayEvents = projects.selectAll(`.${dayEventsClass}`)
        .data((d) => {
          return weekData.days.map((day) => {
            return { day: day, project: d }
          })
        })
        .join(
          (enter) => {
            return enter.append('div')
              .attr('class', (d) => {
                var classes = [dayEventsClass]
                if (d.day === d.project.entry_date) {
                  classes.push(dayEventsStartClass)
                }
                return classes.join(' ')
              })
              .style('left', (d) => {
                var left = dayScale(d.day) >= 0 ? dayScale(d.day) : 0
                if (d.day === d.project.entry_date) {
                  left = left + 1
                }
                return left + '%'
              })
              .style('max-width', (d) => {
                var width = dayScale.bandwidth()
                if (d.day === d.project.entry_date) {
                  width = width - 1
                }
                return `${width}%`
              })
          },
          (update) => {
            return update
          },
          (exit) => {
            return exit.remove()
          }
        )

      var projectLabels = projects.selectAll(`.${this.prefixClass('project', 'label')}`)
        .data((d) => [d])
        .enter()
        .append('div')
        .attr('class', (d) => {
          var classes = [this.prefixClass('project', 'label')]
          if (includesStart(d)) {
            classes.push(this.prefixClass('project', 'label-has-start'))
          }
          if (includesEnd(d)) {
            if (this.getDateFromString(d.exit_date) == new Date()) {

            } else {
              classes.push(this.prefixClass('project', 'label-has-end'))
            }
          }
          return classes.join(' ')
        })
        .style('left', barLeft)
        .style('width', barWidth)

      projectLabels.append('strong').html((d) => d.project_type_name)
      projectLabels.append('span').html((d) => d.project_name)

      const events = Object.keys(this.eventsData).filter((e) => e != 'extrapolation')

      events.forEach((event) => {
        var dayClass = this.prefixClass('day-event')
        var eventClass = this.prefixClass('day-event', event)

        dayEvents.selectAll(`.${dayClass}.${eventClass}`)
          .data((d) => {
            return (d.project[event] || []).filter((n) => n === d.day).map((n) => {
              var datum = { project_type: d.project.project_type, date: n, opacity: 1 }
              if (filters.contactTypes && filters.contactTypes.length > 0) {
                datum.opacity = filters.contactTypes.includes(event) ? 1 : 0.2
              }
              return datum
            })
          })
          .join(
            (enter) => {
              return enter.append('div')
                .attr('class', (d) => {
                  return `project-type-${d.project_type} ${dayClass} ${eventClass}`
                })
                .append('span')
                .attr('class', eventClass)
                .append('i')
                .attr('class', (eventsData[event] || {}).icon)
            },
            (update) => {
              return update.transition()
                .style('opacity', (d) => d.opacity)
            },
            (exit) => {
              return exit.remove()
            }
          )
      })
    })
  }
}
