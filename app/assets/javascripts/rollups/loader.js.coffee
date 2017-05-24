#= require ./namespace

class App.Rollups.Loader
  constructor: (@targets, @rollupPath, @manyClients, @clients, @colorMax) ->
    for p in @targets
      do (p) =>
        $e = $(p)
        $e.append('<div class="rollup-container"/>')
        $.get @rollupPath, partial: $e.data('partial'), (data) =>
          $e.find('.rollup-container').append data
          $e.find('[data-toggle=tooltip]').tooltip()
          # dress up all the id dots
          $e.find('.id-sqr[data-id]').each (i,el)=>
            $id = $(el)
            # if $id.data().always or @manyClients
            # Just always show the squares since they also provide a means of accessing the client GUID
            id = $id.data().id
            [ point, personalID, dataSourceID ] = @clients[id]
            $square = App.util.colorSquare
              point:     point
              low:       0
              high:      @colorMax
              colorLow:  0
              colorHigh: 360
              center:    true
            $square.addClass('rollup__square')
            $square.append dataSourceID
            $html = $ '<div>PersonalID: <span class="pid"/><br>data source: <span/><br><i>click to copy personal id</i></div>'
            $html.css textAlign: 'left', fontSize: 'smaller'
            $html.find('span:first').text personalID
            $html.find('span:last').text dataSourceID
            $square.tooltip html: true, title: $html
            $id.append $square
            $square.click ->
              App.util.copyToClipboard $(@).closest('tr,body').find('div.tooltip:visible .pid')
          $e.find('.rollup-container').siblings('.jRemoveWhenComplete').remove()
        .fail ()->
          $e.find('.rollup-container').append '<div class="alert alert-danger">Failed to load data</div>'
  collapsible: (@target) ->
    $('body').on 'click', @target, (e) =>
      e.preventDefault()
      $t = $(e.currentTarget)
      $others = $t.closest('tbody').find('.' + $t.data('class'))
      $t.toggleClass('open')
      if $t.hasClass('open')
        html = '<span class="icon-minus"></span>'
      else
        html = '<span class="icon-plus"></span>'
      $t.html( html )
      $others.toggle(100)
