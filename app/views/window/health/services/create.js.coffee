<% if @service.errors.any? %>
  $('.jServicesForm .alert.alert-danger').remove()
  $('.jServicesForm').prepend('<div class="alert alert-danger"><%= @service.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/services/service_row', service: @service) %>"
  $('.jServicesList tbody').append(html)
  $('.modal:visible .close').trigger('click')
  
<% end %>