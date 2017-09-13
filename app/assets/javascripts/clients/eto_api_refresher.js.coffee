#= require ./namespace

class App.Clients.EtoApiRefresher
  constructor: (@element, @status_url, @content_url, @fragment_class) ->
    return unless @element.length
    @checker = setInterval(@check_status, 5000)
  check_status: () =>
    $.ajax
      url: @status_url
      dataType: 'json'
      success: (data) =>
        unless data.updating 
          clearInterval(@checker)
          @update_content()
  update_content: () =>
    $.ajax
      url: @content_url
      success: (data) =>
        replacement = $(data).find(@fragment_class)
        $(@fragment_class).replaceWith(replacement)