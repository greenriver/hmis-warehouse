#= require ./namespace

class App.Dashboards.Veterans.Housed
  constructor: (@chart, @labels, @data) ->
    Chart.defaults.global.defaultFontSize = 10
    Chart.defaults.global.elements.rectangle.backgroundColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderWidth = 1

    # @data comes in as counts per day, we currently want to show counts 
    # per month
    month_data = $.map @data, (value, index) ->
      # console.log value, index
    data = 
      labels: @labels,
      datasets: [
        {
          label: 'Exits to PH',
          data: @data,
          backgroundColor: '#45789C',
        }
      ]
    
    housed_chart = new Chart @chart,
      type: 'bar',
      data: data,
      options: 
        bezierCurve: false,
        