#= require ./namespace

class App.Dashboards.Clients.Base
  constructor: (@chart_selector, @sub_population, @support_url, options={}) ->
    Chart.defaults.global.defaultFontSize = 10
    @color_map = {}
    @next_color = 0
    @options = Object.assign({
      legend:
        show: true
        position: 'bottom'
      size:
        height: 200
      remote: false
    }, options)
    if @options.remote
      @_observe()
    else
      @_build_chart()

  _colors: (c, d) =>
    key = d
    if key.id?
      key = key.id
    colors = [ '#091f2f', '#fb4d42', '#288be4', '#d2d2d2' ]
    if key in ['Goal', 'Average', 'Target']
      color = 'rgb(228, 228, 228)'
    else
      color = @color_map[key]
      if !color?
        color = colors[@next_color++]
        @color_map[key] = color
        @next_color = @next_color % colors.length
    return color

  _follow_link: (d, e) =>
    if @support_url
      month = moment(@chart.categories()[d.index] + ' 1', 'MMM YYYY D')
      url = @support_url.replace('START_DATE', month.format('MMM DD, YYYY'))
      url = url.replace('END_DATE', month.endOf('month').format('MMM DD, YYYY'))
      window.open url

  _observe: =>
    @processed = []
    MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if MutationObserver
      (
        new MutationObserver (mutations) =>
          for mutation in mutations
            if $(mutation.target).data('complete') == 'true' && @_selector_exists() && @_selector_unprocessed()
              # console.log($(@chart_selector).data(), @chart_selector)
              @_build_chart()
              @processed.push @chart_selector
      ).observe(
        document.body
        childList: false
        subtree: true
        attributes: true
        attributeFilter: ['complete']
      )

  _selector_exists: =>
    $(@chart_selector).length > 0

  _selector_unprocessed: =>
    @chart_selector not in @processed