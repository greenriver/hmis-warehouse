#= require ./namespace

class App.Weather.Base
  constructor: (@date, @element) ->
    @url = '/weather'
    $.get @url, {date: @date}, (data, text_status, jq_xhr) =>
      return if Object.keys(data).length == 0
      return if data[0] == '<'
      html = '<h3>Weather</h3><p>'
      for item in data
        break if item['description'] == undefined
        html += item['description'] + ' <strong>' + item['value'] + '</strong> ' + item['suffix'] + '<br/>'
      html += '</p>'
      $(@element).html(html)
