#= require ./namespace

class App.Dashboards.Veterans.Exits
  constructor: (@chart, @labels, @data, @options) ->
    Chart.defaults.global.defaultFontSize = 10
    Chart.defaults.global.elements.rectangle.backgroundColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderWidth = 1

    Chart.Tooltip.positioners.custom = (elements, position) ->
      if !elements.length
        return false
      {
        x: position.x
        y: elements[0]._chart.chartArea.bottom
      }
    data = 
      labels: (v for k, v of @labels),
      datasets: (v for k, v of @data),

    @exits_chart = new Chart @chart,
      type: 'bar',
      data: data,
      options:
        onClick: @_follow_link,
        bezierCurve: false,
        scales: 
          xAxes: [
            stacked: true
          ],
          yAxes: [
            stacked: true
          ]
        legend: 
          fullWidth: true,
          position: 'right'
        tooltips:
          mode: 'index'
          position: 'custom'
          callbacks:
            label: (tooltipItem, data) ->
              text = data.datasets[tooltipItem.datasetIndex].label
              value = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];

              # Loop through all datasets to get the actual total of the index
              total = 0
              for set in data.datasets
                total += set.data[tooltipItem.index]

              # If it is not the last dataset, you display it as you usually do
              if (tooltipItem.datasetIndex != data.datasets.length - 1)
                text + " :" + value
              else # .. else, you display the dataset and the total, using an array
                [text + " :" + value, "Total : " + total]
          
  _follow_link: (event) =>
    if target = @exits_chart.getElementAtEvent(event)[0]
      # console.log(target)
      month = @exits_chart.config.data.labels[target._index]
      # console.log(month)
      params = {month: month}
      params['ph'] = true if @options?.ph_only
      url = '/warehouse_reports/veteran_details/exits?' + $.param(params)
      window.open url
    # chart = @charts[event.target.id.replace('census-chart-', '')]
    # project = $(event.target).data('project')

    # # If we clicked on a point, send us to the list of associated clients
    # if point = chart.getElementAtEvent(event)[0]
    #   date = chart.config.data.datasets[point._datasetIndex].data[point._index].x
    #   params = {type: @type, date: date, project: project}
    #   url = @url.replace('date_range', 'details') + '?' + $.param(params)
    #   window.open url
