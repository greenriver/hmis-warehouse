$ ->
  $(document).on 'mouseenter', '.vispdat', (e) ->
    well = $(e.target).closest('.well')
    button = well.find('.save-progress')
    button.css('visibility', 'inherit')

  $(document).on 'mouseleave', '.vispdat', (e) ->
    well = $(e.target).closest('.well')
    button = well.find('.save-progress')
    button.css('visibility', 'hidden')

  $(document).on 'change', '.vispdat-form', (e) ->
    form = $(e.target).closest('form')
    $.ajax
      url: form.data('url'),
      type: 'PATCH',
      data: form.serialize()
    .done (e) ->
      console.log 'done'
    .fail (e) ->
      console.log 'fail'
