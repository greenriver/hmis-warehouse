<% if @backup_plan.errors.any? %>
  $('.jBackupPlansForm .alert.alert-danger').remove()
  $('.jBackupPlansForm').prepend('<div class="alert alert-danger"><%= @backup_plan.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('health/backup_plans/backup_plan_row', backup_plan: @backup_plan) %>"
  $('.jBackupPlansList [data-id="<%= @backup_plan.id %>"]').replaceWith(html)
  $('.modal:visible .close').trigger('click')

<% end %>