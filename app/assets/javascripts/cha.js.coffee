$(document).on 'change', '.cha-form .autosave', (e) ->
  form = $(e.target).closest('form')
  $savingIndicator = $('.j-saving-indicator')
  $savingIndicator.text('Saving').removeClass('hidden saved error').addClass('saving c-spinner')
  $.ajax
    url: form.data('url'),
    type: 'PATCH',
    data: form.serialize()
  .done (e) ->
    # console.log 'done'
    $savingIndicator.removeClass('saving c-spinner error').addClass('saved').text('Saved!')
  .fail (e) ->
    console.log 'fail'
    $savingIndicator.removeClass('saving c-spinner').addClass('error').text('Error saving')
  .always ->
    setTimeout ->
      $savingIndicator.removeClass('saving').addClass('hidden')
    , 20000

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

$(document).on 'change', '.jMarkComplete', (e) ->
  # console.log $(e.target)
  if $(e.target).is(':checked')
    # console.log('enabling')
    $('.jMarkReviewed').removeProp('disabled')
  else
    # console.log('disabling')
    $('.jMarkReviewed').prop('disabled', 'disabled')

$(document).on 'change', '.jSetReviewer', (e) ->
  if $(e.target).is(':checked')
    if !$('.jReviewer').val()
      name = $('.jReviewer').data('name')
      $('.jReviewer').val(name)
  else
    $('.jReviewer').val('')

# disable the review box when we load.  Usually we'd call trigger on the
# .jMarkComplete, but that triggers a save
if $('.jMarkComplete').is(':not(:checked)')
  $('.jMarkReviewed').prop('disabled', 'disabled')

# Scroll to element with id that matches hash
# https://css-tricks.com/snippets/jquery/smooth-scrolling/
scrollToElement = (event, offset=0, duration=1000) ->
  hash = $(event.currentTarget).attr('href')
  $target = $(hash)
  if $target.length
    event.preventDefault()
    $('html, body').animate { scrollTop: $target.offset().top - offset }, duration

$('a[href*="#"]')
  .not('[href="#"]')
  .not('[href="#0"]').on 'click', (event) ->
    scrollToElement event, 20
    event.currentTarget.blur()
