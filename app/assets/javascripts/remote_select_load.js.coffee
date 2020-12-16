#= require namespace

App.remoteSelectLoad ||= {}

App.remoteSelectLoad.init = (root) =>
  $(root || document).find('[data-collection-path]').each () ->
    $select = $(this)
    url = $select.data('collection-path')
    original_placeholder = $select.attr('placeholder') || 'Please choose'
    loading_placeholder = 'Loading...'
    $select.attr('placeholder', loading_placeholder)
    if $select.hasClass('select2')
      $select.select2('destroy')
      $select.select2(placeholder: loading_placeholder)
    $.get url, (data) =>
      $select.append(data)
      $select.attr('placeholder', original_placeholder)
      if $select.hasClass('select2')
        $select.select2('destroy')
        $select.select2(placeholder: original_placeholder)
