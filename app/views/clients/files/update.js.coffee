<% if @file.errors.any? %>
  alert "<%= @file.errors.full_messages.join(', ') %>"
<% else %>
  $(".client-file-<%= @file.id %>").addClass 'highlight'

  setTimeout ->
    $(".client-file-<%= @file.id %>").removeClass('highlight')
  , 2000
<% end %>