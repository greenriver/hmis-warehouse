#= require ./namespace

class App.Rollups.Checker
  constructor: (@path, @checktime=30000) ->
    @link = $('.section-not-loading').has("a[href='#{@path}'")
    @rollupContainer = @link.prev()
    @timer = setTimeout(@checkStatus, @checktime)
  checkStatus: =>
    if @link.prev().has('.rollup').length == 0
      @link.addClass('hide')
    else
      @link.removeClass('hide')
    clearTimeout(@timer)
