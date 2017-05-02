#= require ./namespace

class App.Filter.Controller
  constructor: (@elements) ->
    @elements.select2()
    @elements.on 'change', ->
      $(@).closest('form').submit()
