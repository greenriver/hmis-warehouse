#= require ./namespace

class App.Weather.Base
  constructor: (@date, @element) ->
    @url = '/weather'
    $.get @url, {date: @date}, (data) =>
      html = '<h3>Weather</h3><p>'
      for item in data
        html += item['description'] + ' <strong>' + item['value'] + '</strong> ' + item['suffix'] + '<br/>'
      html += '</p>'
      $(@element).html(html)