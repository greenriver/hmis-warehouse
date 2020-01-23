#= require ./namespace

class App.Sections.Loader
  constructor: (@targets, @rollupPath, @params) ->
    #Load rollups synchronously with a queue
    for p in @targets
      do (p) =>
        $e = $(p)
        $e.append('<div class="rollup-container"/>')
        $(document).queue "fx", =>
          $.get @rollupPath + $e.data('partial'), @params, (data) =>
            $e.find('.rollup-container').append data
            $e.find('.rollup-container').siblings('.jRemoveWhenComplete').remove()
            $(document).dequeue("fx")
            $e.attr('complete', 'true')
            $e.data('complete', 'true')
            # console.log($e)
          .fail ()->
            $e.find('.rollup-container').append '<div class="alert alert-danger">Failed to load data</div>'
            $(document).dequeue("fx")
