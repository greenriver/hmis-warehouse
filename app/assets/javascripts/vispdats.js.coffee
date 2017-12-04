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

    if $(e.target).hasClass('no-auto-save') or $(e.target).hasClass('datepicker')
      $('body').data('needs-refresh', 'true')
      return

    
    if $('body').data('needs-refresh') == "true"
      $('.saving-modal').modal('show')


    form = $(e.target).closest('form')
    $.ajax
      url: form.data('url'),
      type: 'PATCH',
      data: form.serialize()
    .done (e) ->
      console.log 'done'
      if $('body').data('needs-refresh') == "true"
        location.reload()
    .fail (e) ->
      console.log 'fail'
