#= require namespace
#= require select_two

App.select2 ||= {}

App.select2.init = (root) =>
  $(root || document).find('.select2').each () ->
    $select = $(this)
    placeholder = $select.attr('placeholder')
    options = {}
    if placeholder
      options.placeholder = placeholder

    new App.Form.Select2Input this, options
