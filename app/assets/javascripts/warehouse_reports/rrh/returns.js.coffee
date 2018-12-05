#= require ./namespace
class App.WarehouseReports.Rrh.Returns
  constructor: (@wrapper, @data) ->
    @plot()

  plot: =>
    console.log @data
    tt = bb.generate
      data: {
        columns: @data,
        type: "bar",
      },
      tooltip:
        format:
          title: (x) ->
            'Time to Return'
      axis:
        x:
          tick: 
            format: (x) ->
              ''
      color:
        pattern: ["#288be4", "#091f2f", "#fb4d42", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
      bindto: @wrapper