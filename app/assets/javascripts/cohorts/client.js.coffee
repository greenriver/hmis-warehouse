#= require ./namespace

class App.Cohorts.Client
  constructor: (@row_selector, @input_selector) ->
    @init()

  init: ->
    $('body').on 'change', @input_selector, (e) ->
      $(@).closest('form').trigger('submit')
