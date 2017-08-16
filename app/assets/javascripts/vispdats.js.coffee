$ ->
  $(document).on 'mouseenter', '.vispdat', (e) ->
    well = $(e.target).closest('.well')
    button = well.find('.save-progress')
    button.css('visibility', 'inherit')

  $(document).on 'mouseleave', '.vispdat', (e) ->
    well = $(e.target).closest('.well')
    button = well.find('.save-progress')
    button.css('visibility', 'hidden')

  $(document).on 'click', '.save-progress', (e) ->
    button = $(e.target).closest('button')
    button.text('Saving...').prop('disabled', true)
    $.ajax
      url: button.data('url'),
      type: 'PATCH',
      data: $(e.target).closest('form').serialize()
    .done (e) ->
      console.log 'done'
    .fail (e) ->
      console.log 'fail'
