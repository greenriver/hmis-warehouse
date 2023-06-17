#= require ./namespace

class App.Rollups.Checker
  constructor: (@path, @checktime=30000) ->
    @link = $('.section-not-loading').has("a[href='#{@path}'")
    @rollupContainer = @link.prev()
    @timer = setInterval(@checkStatus, @checktime)
  checkStatus: =>
    if @link.prev().has('.rollup').length == 0
      @link.addClass('hide')
      clearInterval(@timer)
    else
      @link.removeClass('hide')
