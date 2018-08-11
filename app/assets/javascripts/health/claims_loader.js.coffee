#= require ./namespace

class App.Health.ClaimsLoader
  constructor: (@patient_batches, @rollupPath) ->
    $(document).find('.jLoading').find('.total-count').text(@patient_batches.length)
    # Load roll-ups synchronously with a queue
    for p in @patient_batches
      do (p) =>
        $(document).queue "fx", =>
          $.get @rollupPath, patient_ids: p, (data) =>
            $(document).find('.jLoading').find('.current-count').text(@patient_batches.length - $(document).queue("fx").length + 1)
            $('.payable-wrapper').append($(data).filter('.payable'))
            $('.unpayable-wrapper').append($(data).filter('.unpayable'))
            $('.duplicate-wrapper').append($(data).filter('.duplicate'))

            $(document).dequeue("fx")
            if $(document).queue("fx").length == 0
              $(document).find('.jLoading').remove()
          .fail ()->
            console.log('failed')
            $(document).dequeue("fx")
