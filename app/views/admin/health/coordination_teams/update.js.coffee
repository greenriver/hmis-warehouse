<% if @team.errors.any? %>
  alert "<%= @team.errors.full_messages.join(', ').html_safe %>"
<% else %>
  $(".team-<%= @team.id %>").addClass 'highlight'
  setTimeout ->
    $(".team-<%= @team.id %>").removeClass('highlight')
  , 2000
<% end %>
