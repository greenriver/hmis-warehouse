#= require namespace

App.remoteSelectLoad ||= {}

App.remoteSelectLoad.init = (root) =>
  $(root || document).find('[data-collection-path]').each () ->
    $select = $(this)
    [url, data] = $select.data('collection-path').split('?')
    original_placeholder = $select.attr('placeholder') || 'Please choose'
    loading_placeholder = 'Loading...'
    $select.attr('placeholder', loading_placeholder)
    if $select.hasClass('select2')
      $select.select2('destroy')
      new App.Form.Select2Input this, { placeholder: loading_placeholder }
    $.post url, data, (data) =>
      $select.append(data)
      $select.attr('placeholder', original_placeholder)
      if $select.hasClass('select2')
        $select.select2('destroy')
        new App.Form.Select2Input this, { placeholder: original_placeholder }
