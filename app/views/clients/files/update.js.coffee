<% if @file.errors.any? %>
  alert "<%= @file.errors.full_messages.join(', ') %>"
<% else %>
  $(".client-file-<%= @file.id %>").addClass 'bg-warning-subtle'

  setTimeout ->
    $(".client-file-<%= @file.id %>").removeClass('bg-warning-subtle')
  , 2000
<% end %>
