#= require namespace
App.init = ->
  $('abbr').tooltip();
  $('body').tooltip({
    selector: '[data-toggle="tooltip"]'
  });

  popovers = new App.Popovers
  popovers.init()
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
  poller = $('[data-poll-every]').first()
  if poller.length > 0
    setInterval ->
      poller.click()
    , poller.data('poll-every')*1000
  # setup click copies
  $('body').on 'click', '.jClickToCopy', ->
    App.util.copyToClipboard $('div.tooltip:visible .pid')

CableReady.operations.alert = (operation) =>
  window.alert(operation.message)
