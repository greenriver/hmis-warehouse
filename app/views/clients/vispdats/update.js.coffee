$('.save-progress').prop('disabled', false).removeClass('btn-default').addClass('btn-success').text "✔︎ SAVED!"

setTimeout ->
  $('.save-progress').removeClass('btn-success').addClass('btn-default').text("Save Progress")
, 2000
