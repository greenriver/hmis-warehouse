App.ClientHistoryCalendar = (data, calendar_selector) => {
  console.log('ClientHistoryCalendar')
  console.log('data', data)
  console.log('calendar_selector', calendar_selector)

  var container = d3.select('.d3-calendar')

  var getDateFromString = (dateString) => {
    var parts = dateString.split('-')
    return new Date(parts[0], parts[1]-1, parts[2])
  }

  var getProjectBorderRaius = (days, date) => {
    return days.includes(date) ? '6px' : '0px'
  }

  var includesDate = (dates, date) => {
    return dates.includes(date)
  }

  var prefixClass = (grouping, item) => {
    var cssClass = `client__calendar-${grouping}`
    if(item){
      return `${cssClass}__${item}`
    }
    return cssClass
  }

  data.forEach((weekData, i) => {
    console.log('weekData', weekData)

    var month = weekData.month
    var dayDomain = weekData.days

    var includesStart = (project) => {return includesDate(weekData.days, project.entry_date)}
    var includesEnd = (project) => {return includesDate(weekData.days, project.exit_date)}
    var barLeft = (d) => {
      var entryDate = dayScale(d.entry_date) >= 0 ? dayScale(d.entry_date) : 0
      if(includesStart(d)) {
        entryDate = entryDate + 1
      }
      return entryDate+'%'
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

    var week = container.append('div')
      .attr('class', prefixClass('week'))
    
    var days = week.selectAll(`.${prefixClass('day')}`)
      .data(dayDomain)
      .enter()
      .append('div')
        .attr('class', (d) => prefixClass('day')+' day-'+d)
        .style('left', (d, i) => (dayScale.bandwidth()*i)+'%')
        .style('width', dayScale.bandwidth()+'%')
        .append('span')
          .text((d) => getDateFromString(d).getDate())
          .attr('class', (d) => getDateFromString(d).getMonth() === month ? prefixClass('date') : `${prefixClass('date')} ${prefixClass('date', 'previous-month')}`)

    var projects = week.selectAll(`${prefixClass('project-container')}`)
      .data(weekData.projects)
      .enter()
      .append('div')
        .attr('class', prefixClass('project-container'))

    var bars = projects.selectAll(`.${prefixClass('project')}`)
      .data((d) => [d])
      .enter()
      .append('div')
        .attr('class', (d) => {
          var classes = [prefixClass('project'), 'project-type-'+d.project_type]
          if(includesStart(d)) {
            classes.push(prefixClass('project', 'has-start'))
          }
          if(includesEnd(d)) {
            classes.push(prefixClass('project', 'has-end'))
          }
          return classes.join(' ')
        })
        .style('margin-left', barLeft)
        .style('width', barWidth)

    projects.selectAll(`.${prefixClass('project', 'extension')}`)
      .data((d) => d.extension ? [d] : [])
      .enter()
      .append('div')
        .attr('class', prefixClass('project', 'extension'))
        .style('left', (d) => barLeft(d.extension))
        .style('width', (d) => barWidth(d.extension))
        .append('i')
          .attr('class', (d) => includesEnd(d.extension) ? 'icon-cross' : '')

    bars.selectAll(`.${prefixClass('project', 'start')}`)
      .data((d) => includesStart(d) && !d.extension_only ? [d] : [])
      .enter()
      .append('div')
        .attr('class', prefixClass('project', 'start'))

    bars.selectAll(`.${prefixClass('project', 'end')}`)
      .data((d) => includesEnd(d) ? [d] : [])
      .enter()
      .append('div')
        .attr('class', prefixClass('project', 'end'))

    var dayEvents = projects.selectAll(`.${prefixClass('project', 'day-events')}`)
      .data((d) => {
        return weekData.days.map((day) => {
          return {day: day, project: d}
        })
      })
      .enter()
      .append('div')
        .attr('class', prefixClass('project', 'day-events'))
        .style('left', (d) => {
          var left = dayScale(d.day) >= 0 ? dayScale(d.day) : 0
          if(d.day === d.project.entry_date) {
            left = left + 1
          }
          return left+'%'
        })
        .style('width', `${dayScale.bandwidth()}%`)

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
      dayEvents.selectAll(`.${prefixClass('day-event', event)}`)
        .data((d) => (d.project[event]||[]).filter((n) => n === d.day))
        .enter()
        .append('span')
          .attr('class', `${prefixClass('day-event')} ${prefixClass('day-event', event)}`)
        .append('i')
          .attr('class', eventIcons[event])
    })

    // bars.append('div')
    //   .attr('class', prefixClass('project', 'name'))
    //   .text(function(d) {
    //     return d.project_name
    //   })
  })
}