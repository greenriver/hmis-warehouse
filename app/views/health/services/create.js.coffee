<% if @service.errors.any? %>
  $('.jBackupPlansForm .alert.alert-danger').remove()
  $('.jBackupPlansForm').prepend('<div class="alert alert-danger"><%= @service.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('health/services/service_row', service: @service) %>"
  $('.jServicesList .jEmpty').remove()
  $('.jServicesList tbody').append(html)
  $('.modal:visible .close').trigger('click')

<% end %>