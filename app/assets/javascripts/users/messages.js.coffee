#= require ./namespace

# singleton class; the constructor is invoked by the layout, replacing the class definition with the singleton instance
class App.Users.Messages
  constructor: (@polling_url, @seen_url) ->
    @messages = []
    @poll()
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
  seen: (id) =>
    $.ajax
      method: 'post'
      url: @seen_url
      dataType: 'json'
      data: id: id
      success: (data) =>
        console.log 'saw', id
  # set up the notification widget
  ringBell: () =>
    $envelope = $ '.messages'
    $badge = $envelope.find('.badge')
    if @messages.length
      $badge.removeClass 'hide'
      $badge.text @messages.length
      $dropdown = $envelope.find '.dropdown-menu'
      $dropdown.find('.message').remove()
      for [ path, id, subject ] in @messages
        $m = $ """
               <li class="dropdown-item message">
                 <a data-loads-in-pjax-modal="true">
                   <i class="icon-envelope-o"/>
                   &nbsp;
                 </a>
               </li>
               """
        $a = $m.find 'a'
        $a.append subject
        $a.attr 'href', path
        $a.click =>
          @seen id
          @messages.find ([p, i, s], index, array) ->
            if id is i
              array.splice index, 1
              return true
          @ringBell()
        $dropdown.append($m)
    else
      $badge.addClass 'hide'
