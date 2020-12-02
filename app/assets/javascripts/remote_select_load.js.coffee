#= require namespace

App.remoteSelectLoad ||= {}

App.remoteSelectLoad.init = (root) =>
  $(root || document).find('[data-collection-path]').each () ->
    $select = $(this)
    url = $select.data('collection-path')
    $select.attr('placeholder', 'Loading...')
    $.get url, (data) =>
      $select.append(data)
      $select.attr('placeholder', 'Please Choose')
      if $select.hasClass('select2')
        $select.select2('destroy')
        $select.select2()
