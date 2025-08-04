#= require ./namespace

class App.ChartsScatterByDate.Chronic extends App.ChartsScatterByDate.Base
  _build_chart: () ->
    id = 0
    scatter_data = $.map @data, (count,date) ->
      {x: date, 'Client count': count}

    data = {
      json: scatter_data,
      keys: {
        x: 'x',
        value: ['Client count']
      },
      type: 'scatter',
      color: (color, d) =>
        # d.x is a date object from the timeseries axis
        if d.x.toISOString().substring(0, 10) == @current_date
          'black'
        else
          '#4cab90' # Default color
      onclick: (d, element) => @_follow_link(d)
      onover: (d, element) => @_process_hover(d)
      onout: (d, element) => @_process_hover_out(d)
    }
    options =
      point:
        r: 3
      tooltip:
        contents: (d) => @_format_tooltip_contents(d)

    @_individual_chart(data, id, options)

  _follow_link: (d) =>
    # d.x is a date object
    date = d.x.toISOString().substring(0,10)
    $('.jFilterOn').val(date)
    $('.jFilter').submit()

  _process_hover: (d) =>
    @element.css('cursor', 'pointer')

  _process_hover_out: (d) =>
    @element.css('cursor', 'default')
