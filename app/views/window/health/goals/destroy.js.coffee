<% if @goal.errors.any? %>
  alert "<%= @goal.errors.full_messages.join(', ') %>"
<% else %>
  $('.jGoal[data-id="<%= @goal.id %>"]').remove()  
<% end %>