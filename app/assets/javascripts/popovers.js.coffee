#= require ./namespace

class App.Popovers
  init: () =>
    $('body').popover({
      selector: '[data-toggle="popover"]',
      content: ()->
        url = $(this).data('url')
        if url
          $.ajax url,
            type: 'GET'
            dataType: 'html'
            success: (data)=>
              $(this).attr('data-content', data)
              $(this).popover('hide')
              $(this).popover('show')
          'Loading...'
        else
          $(this).data('content')
    });
