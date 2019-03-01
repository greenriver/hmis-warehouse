#= require ./namespace

class App.DataQualityReports.TimeToExit extends App.DataQualityReports.Base
  _data_object: (data) ->
    hash = {}
    for k,v of data
      hash[k] = [ 14, v]
    return hash

  _format_data: (data) ->
    {
      labels: ["Goal", "This Program"],
      data: this._data_object(data)
    }


  _build_chart: ->
    @chart = bb.generate
      bindto: @chart_selector
      data: {json: @data['data'], type: "bar", onclick: @_follow_link}
      axis:
        x:
          type: "category",
          categories: @data['labels'],