#= require namespace
App.init = ->
  App.select2.init()
  $('abbr').tooltip();
  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
  $.fn.datepicker.defaults.format = "M d, yyyy";
  $('.nav-tabs .active-tab').on 'click', 'a', (e)->
    e.preventDefault()
  $('.colorpicker').minicolors(theme: 'bootstrap')
  $(document).on 'click', '.jCheckAll', (e) ->
    id = $(this).attr('id')
    checked = $(this).prop('checked')
    $('input.' + id).prop('checked', checked)
  return true


# TODO may also need to do on pjax_modal change
$ ->
  App.init()
  $('.datepicker.enable-on-load, .date_picker.enable-on-load')
    .prop('disabled', false)
    .datepicker()
  $('.datetimepicker, .date_time_picker').datetimepicker({
    sideBySide: true,
    stepping: 15,
    format: "MMM D, YYYY h:mm a"
  })
  poller = $('[data-poll-every]').first()
  if poller.length > 0
    setInterval ->
      poller.click()
    , poller.data('poll-every')*1000
