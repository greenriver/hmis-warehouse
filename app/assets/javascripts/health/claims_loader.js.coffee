#= require ./namespace

class App.Health.ClaimsLoader
  constructor: (@patient_batches, @rollupPath) ->
    # Load roll-ups synchronously with a queue
    for p in @patient_batches
      do (p) =>
        $(document).queue "fx", =>
          $.get @rollupPath, patient_ids: p, (data) =>
            $('.payable-wrapper').append($(data).filter('.payable'))
            $('.unpayable-wrapper').append($(data).filter('.unpayable'))
            $('.duplicate-wrapper').append($(data).filter('.duplicate'))
            $(document).dequeue("fx")
            if $(document).queue("fx").length == 0
              $(document).find('.jLoading').remove()
          .fail ()->
            console.log('failed')
            $(document).dequeue("fx")
