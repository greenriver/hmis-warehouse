#= require ./namespace

class App.WarehouseReports.Cas.DecisionEfficiency
  constructor: (@chart) ->
    @legal_steps = @chart.data('legal-steps')
    Chart.defaults.global.defaultFontSize = 10

    @_prep_ui()
    $('#new_steps').submit()

  _prep_ui: () =>
    $('#new_steps').on 'submit', (e) =>
      e.preventDefault()
      $form = $(e.currentTarget)
      $p = $.getJSON($form.attr('action'), $form.serialize())
      $p.success (data, status, xhr) =>
        @plot(data)
        @set_stats(data)

    $('#new_steps').on 'change', ':input', (e) =>
      $form = $(e.delegateTarget)
      $s1 = $form.find('#first-step')
      $s2 = $form.find('#second-step')
      target = e.currentTarget
      if target == $s1[0]
        v2 = $s2.val()
        $s2.find('option').remove()
        set_step = false
        $selected = $(target).find(':selected')
        $.each @legal_steps[$s1.val()], ->
          $option = $('<option/>').text(@).val(@)
          if @ == v2
            set_step = true
            $option.prom('selected', true)
          $s2.append($option)
        if ! set_step
          $s2.find('option:last').prop('selected', true)
      $form.submit()

    

  plot: (data) =>
    labels = data['labels']
    datasets = []
    for title, counts of data['data_sets']
      hash = window.App.util.hashCode(title)
      color = window.App.util.intToRGB(hash * 200)
      datasets.push
        label: title,
        data: counts,
        backgroundColor: "##{color}",
        hoverBackgroundColor: "##{color}"
    if chart = @chart.data('chart')
      chart.destroy()
    chart = new Chart @chart, 
      type: 'bar',
      data: 
        labels: labels,
        datasets: datasets,
      options: 
        scales: 
          xAxes: [
            stacked: true,
            scaleLabel:
              display: true,
              labelString: $('.jUnits :selected').text()
          ],
          yAxes: [
            stacked: true,
            scaleLabel:
              display: true,
              labelString: 'Matches'
            ,
            ticks:
              beginAtZero: true,
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
              value = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index]
              # Loop through all datasets to get the actual total of the index
              total = 0
              for set in data.datasets
                total += set.data[tooltipItem.index]

              # If it is not the last dataset, you display it as you usually do
              if (tooltipItem.datasetIndex != data.datasets.length - 1)
                text + " :" + value
              else # .. else, you display the dataset and the total, using an array
                [text + " :" + value, "Total : " + total]
      
    @chart.data('chart', chart)
    

  round: (n, places) ->
    v = 10 ** places
    Math.round(n * v) / v

  set_stats: (data) ->
    text = ''
    for label, number of data['stats']
      text += '<span class="stat"><label>' + label.replace('_', ' ') + ':</label> <span>' + number + '</span></span>'
    $('#stats').html(text)
