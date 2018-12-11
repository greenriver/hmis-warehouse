#= require ./namespace
class App.WarehouseReports.Rrh.Destination
  constructor: (@wrapper, @legend_wrapper, @data) ->
    @plot()

  plot: =>
    tt = bb.generate
      data: {
        columns: @data,
        type: "pie",
      },
      pie: 
        label:
          format: (value, ratio, id) ->
            "#{value} (#{d3.format(".0%")(ratio)})"
      tooltip:
        format:
          value: (value, ratio, id, index) ->
            "#{value} (#{d3.format(".0%")(ratio)})"
      color:
        pattern: ["#fb4d42", "#288be4", "#091f2f", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
      bindto: @wrapper