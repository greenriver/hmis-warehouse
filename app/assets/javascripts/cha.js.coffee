$(document).on 'change', '.cha-form.autosave', (e) ->
  form = $(e.target).closest('form')
  $.ajax
    url: form.data('url'),
    type: 'PATCH',
    data: form.serialize()
  .done (e) ->
    console.log 'done'
  .fail (e) ->
    console.log 'fail'

$(document).on 'click', '.add-diagnosis', (e) ->
  $('.diagnosis-row.hidden').first().removeClass('hidden')

$(document).on 'click', '.remove-diagnosis', (e) ->
  row = $(e.target).closest('.diagnosis-row').first()
  inputs = row.find(':input')
  inputs.val('')
  inputs.first().change()
  row.addClass('hidden')

$(document).on 'click', '.add-medication', (e) ->
  $('.medication-rows.hidden').first().removeClass('hidden')

$(document).on 'click', '.remove-medication', (e) ->
  row = $(e.target).closest('.medication-rows').first()
  inputs = row.find(':input')
  inputs.val('')
  inputs.first().change()
  row.addClass('hidden')

