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
    $('body').on('shown.bs.popover', (e)->
        $(e.target).data('bs.popover')._activeTrigger.click = true
    );
