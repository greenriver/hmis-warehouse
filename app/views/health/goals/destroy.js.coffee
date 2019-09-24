<% if @goal.errors.any? %>
  alert "<%= @goal.errors.full_messages.join(', ') %>"
<% else %>
  $('.jGoal[data-id="<%= @goal.id %>"]').remove()
  $rows = $('.health-care-plan__goal-list .jGoal')
  $rows.each (index, row) -> 
    $(this).find('.c-card__item-header h4').text('Goal #'+(index+1))  
<% end %>