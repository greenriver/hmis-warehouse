<% if @goal.errors.any? %>
  $('form.jGoal .alert.alert-danger').remove()
  $('form.jGoal').prepend('<div class="alert alert-danger"><%= @goal.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render(@goal, readonly: true) %>"
  rowSelector = '.jGoal[data-id="<%= @goal.id %>"]'
  $row = $(rowSelector)
  $(html).insertAfter(rowSelector)
  $row.remove()
  $rows = $('.health-care-plan__goal-list .jGoal')
  $rows.each (index, row) -> 
    $(this).find('.c-card__item-header h4').text('Goal #'+(index+1))
  $('.modal:visible .close').trigger('click')
  
<% end %>