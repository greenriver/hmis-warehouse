<% if @goal.errors.any? %>
  $('form.jGoal .alert.alert-danger').remove()
  $('form.jGoal').prepend('<div class="alert alert-danger"><%= @goal.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render(@goal, readonly: true) %>"
  $('.health-care-plan__goal-list .jEmpty').remove()
  $('.health-care-plan__goal-list').append(html)
  $('.modal:visible .close').trigger('click')
  
<% end %>