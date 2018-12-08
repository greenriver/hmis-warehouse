#= require ./namespace
class App.WarehouseReports.Rrh.Returns
  constructor: (@wrapper, @data) ->
    @plot()

  plot: =>
    tt = bb.generate
      data: {
        columns: @data.data,
        type: "bar",
      },
      axis:
        x:
          tick:
            format: (i, category_name) =>
              @data.labels[i]
      tooltip:
        format:
          title: (i) =>
            'Time to Return ' + @data.labels[i]
      
      color:
        pattern: ["#fb4d42", "#288be4", "#091f2f", "#58585b", "#9E788F", "#A4B494", "#F3B3A6", "#F18F01", "#E59F71", "#ACADBC", "#D0F1BF"]
      bindto: @wrapper