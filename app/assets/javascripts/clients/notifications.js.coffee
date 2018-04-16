#= require ./namespace

class App.Clients.Notifications
  constructor: (@polling_url, @seen_url) ->
    @notifications = []
    @checker = setInterval(@poll, 60000)
  # look for notifications to display
  poll: () =>
    console.log 'polling for notifications...'
    $.ajax
      method: 'get'
      url: @polling_url
      dataType: 'json'
      data: ids: ( n.id for n in @notifications )
      success: (data) =>
        console.log 'polled', data
        seen = new Set()
        for n in @notifications
          seen.add n.id
        for n in data
          unless seen.has n.id
            @notifications.push n
  # mark a notification as seen
  seen: (notification) =>
    $.ajax
      method: 'post'
      url: @seen_url
      dataType: 'json'
      data: id: notification.id
      success: (data) =>
        console.log 'saw', notification, data
