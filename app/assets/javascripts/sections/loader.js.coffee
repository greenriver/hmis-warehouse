#= require ./namespace

class App.Sections.Loader
  constructor: (@targets, @rollupPath, @params) ->
    #Load rollups synchronously with a queue
    for p in @targets
      do (p) =>
        $e = $(p)
        $e.html('<div class="rollup-container well"/>')
        $(document).queue "fx", =>
          $.get @rollupPath + $e.data('partial'), @params, (data) =>
            $e.find('.rollup-container').removeClass('well')
            $e.find('.rollup-container').append data
            $e.find('.rollup-container').siblings('.jRemoveWhenComplete').remove()
            $(document).dequeue("fx")
            $e.attr('complete', 'true')
            $e.data('complete', 'true')
            # console.log($e)
          .fail ()->
            $e.find('.rollup-container').append '<div class="alert alert-danger">Failed to load data</div>'
            $e.find('.rollup-container').removeClass('well')
            $(document).dequeue("fx")
