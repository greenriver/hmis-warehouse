class AppClientHistoryCalendar {
  constructor(data, eventsData, calendar_selector) {
    console.log('ClientHistoryCalendar')
    console.log('data', data)
    console.log('eventsData', eventsData)
    console.log('calendar_selector', calendar_selector)
    this.data = data
    this.container = d3.select('.d3-calendar')
  }

  getDateFromString(dateString) {
    var parts = dateString.split('-')
    return new Date(parts[0], parts[1]-1, parts[2])
  }

  includesDate(dates, date) {
    return dates.includes(date)
  }

  prefixClass(grouping, item) {
    var cssClass = `client__calendar-${grouping}`
    if(item){
      return `${cssClass}__${item}`
    }
    return cssClass
  }

  draw(filters) {

    console.log('filters', filters)

    this.data.forEach((weekData, i) => {
      console.log('weekData', weekData)

      var projectData = weekData.projects.map((p) => {
        var opacity = 1
        var inProjectType = true
        var inProjectName = true
        if(filters.projectTypes && filters.projectTypes.length > 0) {
          opacity = filters.projectTypes.includes(`${p.project_type}`) ? 1 : 0.2
          inProjectType = filters.projectTypes.includes(`${p.project_type}`)
        }
        if(filters.projectNames && filters.projectNames.length > 0) {
          opacity = filters.projectNames.includes(p.project_name) && inProjectType ? 1 : 0.2
          inProjectName = filters.projectNames.includes(p.project_name) && inProjectType
        }
        if(filters.contactTypes && filters.contactTypes.length > 0) {
          filters.contactTypes.every((ct) => {
            if (p[ct] && p[ct].length > 0 && inProjectType && inProjectName) {
              opacity = 1
              return false
            } else {
              opacity = 0.2
              return true
            }
          })
        }
        p.opacity = opacity
        return p
        
      })

      var month = weekData.month
      var dayDomain = weekData.days

      var includesStart = (project) => {return this.includesDate(weekData.days, project.entry_date)}
      var includesEnd = (project) => {return this.includesDate(weekData.days, project.exit_date)}
      var barLeft = (d) => {
        var entryDate = dayScale(d.entry_date) >= 0 ? dayScale(d.entry_date) : 0
        if(includesStart(d)) {
          entryDate = entryDate + 1
        }
        return entryDate + '%'
      }

      var barWidth = (d) => {
        var entryDate = includesStart(d) ? dayScale(d.entry_date) : 0
        var exitDate = includesEnd(d) ? dayScale(d.exit_date) : 100
        if(includesEnd(d)) {
          exitDate = exitDate + dayScale.bandwidth()
        }
        var width = exitDate-entryDate >= 0 ? (exitDate-entryDate) : 0
        if(includesStart(d)) {
          width = width - 1
        }
        if(includesEnd(d)) {
          width = width - 1
        }
        return width+'%'
      }

      var dayScale = d3.scaleBand()
        .domain(dayDomain)
        .range([0,100])

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
          .style('width', dayScale.bandwidth()+'%')
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
          .attr('class', (d) => this.prefixClass('day')+' day-'+d)
          .style('left', (d, i) => (dayScale.bandwidth()*i)+'%')
          .style('width', dayScale.bandwidth()+'%')
          .append('span')
            .text((d) => this.getDateFromString(d).getDate())
            .attr('class', (d) => this.getDateFromString(d).getMonth() === month ? this.prefixClass('date') : `${this.prefixClass('date')} ${this.prefixClass('date', 'previous-month')}`)

      var projectClass = this.prefixClass('project-container')
      var projects = week.selectAll(`.${projectClass}`)
        .data(projectData)
        .join(
          function(enter) {
            return enter.append('div')
              .attr('class', (d, i) => {
                return `${projectClass} ${projectClass}__${i}`
              })
              .style('opacity', (d) => d.opacity)
          },
          function(update) {
            return update.transition().style('opacity', (d) => d.opacity)
          },
          function(exit) {
            return exit.remove()
          }
        )

      // var tooltips = week.selectAll(`.${this.prefixClass('project-tooltip')}`)
      //   .data(projectData)
      //   .enter()
      //   .append('div')
      //     .attr('class', this.prefixClass('project-tooltip'))
      //     .text('testing')
      //     .style('top', (d, i) => {
      //       var p = d3.select(`.${projectClass}__${i}`)
      //       var box = p.node().getBoundingClientRect()
      //       var parentBox = p.node().parentNode.getBoundingClientRect()
      //       console.log('box', box)
      //       console.log('parentBox', parentBox)
      //       return '0px'
      //     })
        
      var bars = projects.selectAll(`.${this.prefixClass('project')}`)
        .data((d) => [d])
        .enter()
        .append('div')
          .attr('class', (d) => {
            if(d.extension_only) {
              var classes = [this.prefixClass('project')]
            } else {
              var classes = [this.prefixClass('project'), 'project-type-'+d.project_type]
            }
            
            if(includesStart(d)) {
              classes.push(this.prefixClass('project', 'has-start'))
            }
            if(includesEnd(d)) {
              classes.push(this.prefixClass('project', 'has-end'))
            }
            if(!d.bed_nights && !d.extension && !d.current_situations && !d.move_in_dates && !d.service_dates && !d.ce_events && !d.custom_events) {
              classes.push(this.prefixClass('project', 'no-events'))
            }
            return classes.join(' ')
          })
          .style('margin-left', barLeft)
          .style('width', barWidth)

      const extensionClass = this.prefixClass('project', 'extension')
      projects.selectAll(`.${extensionClass}`)
        .data((d) => d.extension ? [d] : [])
        .join(
          function(enter) {
            return enter.append('div')
              .attr('class', extensionClass)
              .style('left', (d) => barLeft(d.extension))
              .style('width', (d) => barWidth(d.extension))
              .append('i')
                .attr('class', (d) => includesEnd(d.extension) ? 'icon-cross' : '')
          },
          function(update) {
            update.style('opacity', (d) => {
              if(filters.contactTypes && filters.contactTypes.length > 0) {
                return filters.contactTypes.includes('extension') ? 1 : 0.2
              }
              return 1
            })
          },
          function(exit) {
            return exit.remove()
          }
        )

      bars.selectAll(`.${this.prefixClass('project', 'start')}`)
        .data((d) => includesStart(d) && !d.extension_only ? [d] : [])
        .enter()
        .append('div')
          .attr('class', this.prefixClass('project', 'start'))

      bars.selectAll(`.${this.prefixClass('project', 'end')}`)
        .data((d) => includesEnd(d) ? [d] : [])
        .enter()
        .append('div')
          .attr('class', this.prefixClass('project', 'end'))

      const dayEventsClass = this.prefixClass('project', 'day-events')
      const dayEventsStartClass = this.prefixClass('project', 'day-events-has-start')
      
      var dayEvents = projects.selectAll(`.${dayEventsClass}`)
        .data((d) => {
          return weekData.days.map((day) => {
            return {day: day, project: d}
          })
        })
        .join(
          function(enter) {
            return enter.append('div')
              .attr('class', (d) => {
                var classes = [dayEventsClass]
                if(d.day === d.project.entry_date) {
                  classes.push(dayEventsStartClass)
                }
                return classes.join(' ')
              })
              .style('left', (d) => {
                var left = dayScale(d.day) >= 0 ? dayScale(d.day) : 0
                if(d.day === d.project.entry_date) {
                  left = left + 1
                }
                return left+'%'
              })
              .style('max-width', (d) => {
                var width = dayScale.bandwidth()
                if(d.day === d.project.entry_date) {
                  width = width - 1
                }
                return `${width}%`
              })
          },
          function(update) {
            return update
          },
          function(exit) {
            return exit.remove()
          }
        )

      var projectLabels = projects.selectAll(`.${this.prefixClass('project', 'label')}`)
        .data((d) => [d])
        .enter()
        .append('div')
          .attr('class', (d) => {
            var classes = [this.prefixClass('project', 'label')]
            if(includesStart(d)) {
              classes.push(this.prefixClass('project', 'label-has-start'))
            }
            if(includesEnd(d)) {
              classes.push(this.prefixClass('project', 'label-has-end'))
            }
            return classes.join(' ')
          })
          .style('left', barLeft)
          .style('width', barWidth)

      projectLabels.append('strong').html((d) => d.project_type_name)
      projectLabels.append('span').html((d) => d.project_name)

      const events = Object.keys(eventsData).filter((e) => e != 'extension')

      events.forEach((event) => {
        var dayClass = this.prefixClass('day-event')
        var eventClass = this.prefixClass('day-event', event)
        
        dayEvents.selectAll(`.${dayClass}.${eventClass}`)
          .data((d) => {
            return (d.project[event]||[]).filter((n) => n === d.day).map((n) => {
              var datum = {project_type: d.project.project_type, date: n, opacity: 1}
              if(filters.contactTypes && filters.contactTypes.length > 0) {
                datum.opacity = filters.contactTypes.includes(event) ? 1 : 0.2
              }
              return datum
            })
          })
          .join(
            function(enter) {
              return enter.append('div')
                .attr('class', (d) => {
                  return `project-type-${d.project_type} ${dayClass} ${eventClass}`
                })
                .append('span')
                  .attr('class', eventClass)
                  .append('i')
                    .attr('class', (eventsData[event]||{}).icon)
            },
            function(update) {
              return update.transition()
                .style('opacity', (d) => d.opacity)
            },
            function(exit) {
              return exit.remove()
            }
          )
          
      })


    })

  }
}