#= require ./namespace

class App.Users.Messages
  constructor: (@polling_url, @seen_url) ->
    @messages = []
    setInterval @poll, 60000
  # look for messages to display
  poll: () =>
    console.log 'polling for messages...'
    $.ajax
      method: 'get'
      url: @polling_url
      dataType: 'json'
      data: ids: ( n.id for n in @messages )
      success: (data) =>
        console.log 'polled', data
        seen = new Set()
        for n in @messages
          seen.add n.id
        for n in data
          unless seen.has n.id
            @messages.push n
        @ringBell()
  # mark a message as seen
  seen: (message) =>
    $.ajax
      method: 'post'
      url: @seen_url
      dataType: 'json'
      data: id: message.id
      success: (data) =>
        console.log 'saw', message, data
  ringBell: () =>
    $bell = $ '.messages'
    if @messages.length
      $bell.removeClass 'hide'
      $bell.find('.message-count').text @messages.length
    else
      $bell.addClass 'hide'
