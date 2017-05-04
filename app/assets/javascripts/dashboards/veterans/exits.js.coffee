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
        tooltips:
          mode: 'index'
          position: 'nearest'
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