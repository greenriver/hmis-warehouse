#= require ./namespace

class App.ChartsScatterByDate.Chronic extends App.ChartsScatterByDate.Base
  _build_chart: () ->
    Chart.defaults.global.elements.point.radius = 3
    id = 0
    scatter_data = $.map @data, (count,date) ->
      {x: date, y: count}
    colors = $.map @data, (count,date) =>
      if date == @current_date then 'black' else '#4cab90'
    data = {
        datasets: [{
            label: 'Client count',
            data: scatter_data,
            pointBackgroundColor: colors,
            pointBorderColor: colors,
        }],
        title: {display: true, text: 'Counts by day'}
    }

    util = window.App.util.new
    for i of data.datasets
      hash = window.App.util.hashCode(data.title.text)
      color = window.App.util.intToRGB(hash + i * 200)
      data.datasets[i].borderColor = "\##{color}"
      data.datasets[i].backgroundColor = "transparent"
      data.datasets[i].lineTension = 0
      data.datasets[i].borderWidth = 1
    options =
      tooltips: 
        callbacks:
          label: @_format_tooltip_label
    @_individual_chart(data, id, options)
  
  _follow_link: (event) =>
    chart = @charts[event.target.id.replace('chart-chart-', '')]

    # If we clicked on a point, send us to the list of associated clients
    if point = chart.getElementAtEvent(event)[0]
      date = chart.config.data.datasets[point._datasetIndex].data[point._index].x
      $('.jFilterOn').val(date)
      $('.jFilter').submit()
      # 
      # params = {type: @type, date: date, project: project}
      # url = @url.replace('date_range', 'details') + '?' + $.param(params)
      # window.open url
  _process_hover: (event, item) =>
    if item.length
      @element.css('cursor', 'pointer')
    else
      @element.css('cursor', 'default')