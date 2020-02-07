<% if @backup_plan.errors.any? %>
  alert "<%= @backup_plan.errors.full_messages.join(', ') %>"
<% else %>
  $('.jBackupPlansList [data-id="<%= @backup_plan.id %>"]').remove()
  $('.modal:visible .close').trigger('click')
<% end %>