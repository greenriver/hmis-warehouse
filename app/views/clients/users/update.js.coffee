<% if @user.errors.any? %>
  alert "<%= @user.errors.full_messages.join(', ') %>"
<% else %>
  $(".user-client-<%= @user.id %>").addClass 'highlight'

  setTimeout ->
    $(".user-client-<%= @user.id %>").removeClass('highlight')
  , 2000
<% end %>
