<% if @user.errors.any? %>
  alert "<%= @user.errors.full_messages.join(', ') %>"
<% else %>
  $(".user-client-<%= @user.id %>").addClass 'bg-warning-subtle'

  setTimeout ->
    $(".user-client-<%= @user.id %>").removeClass('bg-warning-subtle')
  , 2000
<% end %>
