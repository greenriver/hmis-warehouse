#= require ./namespace

class App.Sections.Loader
  constructor: (@targets, @rollupPath, @params) ->
    #Load rollups synchronously with a queue
    for p in @targets
      do (p) =>
        $e = $(p)
        $e.html('<div class="rollup-container well"/>')
        loader = (data, status, xhr) =>
          if xhr.status == 202
            setTimeout fetch_rollup, 10000
          else
            $e.find('.rollup-container').removeClass('well')
            $e.find('.rollup-container').append data
            $e.find('.rollup-container').siblings('.jRemoveWhenComplete').remove()
            $(document).dequeue("fx")
            $e.attr('complete', 'true')
            $e.data('complete', 'true')
            # console.log($e)
        fail = ()->
          $e.find('.rollup-container').append '<div class="alert alert-danger">Failed to load data</div>'
          $e.find('.rollup-container').removeClass('well')
          $(document).dequeue("fx")
        fetch_rollup = ()=>
          console.log('attempting')
          $.get(@rollupPath + $e.data('partial'), @params, loader).fail(fail)
        $(document).queue "fx", =>
          fetch_rollup()
