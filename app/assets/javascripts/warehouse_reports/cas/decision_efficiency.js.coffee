#= require ./namespace

class App.WarehouseReports.Cas.DecisionEfficiency
  constructor: (@chart) ->
    @legal_steps = @chart.data('legal-steps')
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
      datasets.push
        label: title,
        data: counts
    if chart = @chart.data('chart')
      chart.destroy()
    chart = new Chart @chart, 
      type: 'bar',
      options: 
        legend:
          display: false
        ,
        scales: 
          xAxes: [
            {
              stacked: true,
              scaleLabel: {
                display: true,
                labelString: $('.jUnits :selected').text()
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              scaleLabel: {
                display: true,
                labelString: 'Matches'
              },
              ticks: {
                beginAtZero: true,
                stepSize: 1
              }
            }
          ]
      ,
      data: 
        labels: labels,
        datasets: datasets,
    @chart.data('chart', chart)
    

  round: (n, places) ->
    v = 10 ** places
    Math.round(n * v) / v

  set_stats: (data) ->
    text = ''
    for label, number of data['stats']
      text += '<span class="stat"><label>' + label.replace('_', ' ') + ':</label> <span>' + number + '</span></span>'
    $('#stats').html(text)
