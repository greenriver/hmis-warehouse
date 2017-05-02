#= require ./namespace

class App.Dashboards.Veterans.Exits
  constructor: (@chart, @labels, @data) ->
    Chart.defaults.global.defaultFontSize = 10
    Chart.defaults.global.elements.rectangle.backgroundColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderColor = '#45789C'
    Chart.defaults.global.elements.rectangle.borderWidth = 1


    data = 
      labels: (v for k, v of @labels),
      datasets: (v for k, v of @data),

    exits_chart = new Chart @chart,
      type: 'bar',
      data: data,
      options: 
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