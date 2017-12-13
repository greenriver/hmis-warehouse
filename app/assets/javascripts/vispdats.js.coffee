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

  $(document).on 'change', '.number-of-bedrooms', (e) ->
    nob = $('.number-of-bedrooms option:selected')
    if nob.text() == 'other'
      e.stopPropagation()
      $('.number-of-bedrooms-other').closest('.form-group').show();
      $('.number-of-bedrooms-other').prop('disabled', false)
    else
      $('.number-of-bedrooms-other').closest('.form-group').hide();
      $('.number-of-bedrooms-other').prop('disabled', true)
      $('.number-of-bedrooms-other').val('')
  $('.number-of-bedrooms').trigger('change')