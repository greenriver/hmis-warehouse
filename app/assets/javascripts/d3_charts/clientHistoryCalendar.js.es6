class AppClientHistoryCalendar {
  constructor(data, calendar_selector) {
    console.log('ClientHistoryCalendar')
    console.log('data', data)
    console.log('calendar_selector', calendar_selector)
    this.data = data
    this.container = d3.select('.d3-calendar')
  }

  

  // var container = d3.select('.d3-calendar')
  // var containerBox = container.node().getBoundingClientRect()

  getDateFromString(dateString) {
    var parts = dateString.split('-')
    return new Date(parts[0], parts[1]-1, parts[2])
  }

  // getProjectBorderRaius = (days, date) => {
  //   return days.includes(date) ? '6px' : '0px'
  // }

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

      var projectData = weekData.projects.filter((p) => {
        if(filters.projectType && filters.projectType.length) {
          return filters.projectType.includes(`${p.project_type}`)
        }
        return true
      })
      console.log('projects', projectData)
      // console.log('weekData again', weekData)

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
            return enter.append('div').attr('class', projectClass)
          },
          function(update) {
            return update
          },
          function(exit) {
            console.log('exit', exit)
            return exit.remove()
          }
        )
        // .enter()
        // .append('div')
        //   .attr('class', this.prefixClass('project-container'))
      // projects = week.selectAll(`.${projectClass}`)
      console.log('project selection', projects)
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

      projects.selectAll(`.${this.prefixClass('project', 'extension')}`)
        .data((d) => d.extension ? [d] : [])
        .enter()
        .append('div')
          .attr('class', this.prefixClass('project', 'extension'))
          .style('left', (d) => barLeft(d.extension))
          .style('width', (d) => barWidth(d.extension))
          .append('i')
            .attr('class', (d) => includesEnd(d.extension) ? 'icon-cross' : '')

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

      var dayEvents = projects.selectAll(`.${this.prefixClass('project', 'day-events')}`)
        .data((d) => {
          return weekData.days.map((day) => {
            return {day: day, project: d}
          })
        })
        .enter()
        .append('div')
          .attr('class', (d) => {
            var classes = [this.prefixClass('project', 'day-events')]
            if(d.day === d.project.entry_date) {
              classes.push(this.prefixClass('project', 'day-events-has-start'))
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

      const events = [
        'bed_nights', 
        'current_situations', 
        'move_in_dates',
        'service_dates',
        'ce_events',
        'custom_events',
      ]

      const eventIcons = {
        bed_nights: 'icon-moon-inv',
        current_situations: 'icon-download2',
        move_in_dates: 'icon-enter',
        service_dates: 'icon-clip-board-check',
        ce_events: '',
        custom_events: '',
      } 

      events.forEach((event) => {
        dayEvents.selectAll(`.${this.prefixClass('day-event', event)}`)
          .data((d) => {
            return (d.project[event]||[]).filter((n) => n === d.day).map((n) => {
              return {project_type: d.project.project_type, date: n}
            })
          })
          .enter()
          .append('div')
            .attr('class', (d) => {
              return `project-type-${d.project_type} ${this.prefixClass('day-event')}`
            })
            .append('span')
              .attr('class', `${this.prefixClass('day-event', event)}`)
              .append('i')
                .attr('class', eventIcons[event])
      })

    })

  }
}