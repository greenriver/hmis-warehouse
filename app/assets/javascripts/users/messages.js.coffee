#= require ./namespace

# singleton class; the constructor is invoked by the layout, replacing the class definition with the singleton instance
class App.Users.Messages
  constructor: (@polling_url, @seen_url) ->
    @messages = []
    @poll()
    @polled_count = 0
    @interval = setInterval @poll, 60000
  # look for messages to display
  poll: () =>
    # console.log "polling for messages...(#{@polled_count})"
    @polled_count += 1
    if @polled_count > 5
      console.log "No longer polling for messages after #{@polled_count} times polling"
      clearInterval(@interval)
      return
    $.ajax
      method: 'get'
      url: @polling_url
      dataType: 'json'
      data: ids: ( n.id for n in @messages )
      success: (data) =>
        # console.log 'polled', data
        seen = new Set()
        for n in @messages
          seen.add n.id
        for n in data.messages
          unless seen.has n.id
            @messages.push n
        @unseen_count = data.count
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
    $envelope = $ '.email-messages'
    $badge = $envelope.find('.badge')
    $dropdown = $envelope.find '.dropdown-menu'
    $dropdown.find('.message').remove()
    if @messages.length
      $badge.removeClass 'hide'
      $badge.text @unseen_count
      for [ path, id, subject ] in @messages
        do (path, id, subject) =>
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
            @unseen_count -= 1
            @ringBell()
          $dropdown.prepend($m)
    else
      $badge.addClass 'hide'
