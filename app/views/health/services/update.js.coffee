<% if @service.errors.any? %>
  $('.jServicesForm .alert.alert-danger').remove()
  $('.jServicesForm').prepend('<div class="alert alert-danger"><%= @service.errors.full_messages.join(', ') %></div>')
  $('.modal-body').scrollTop(0)
<% else %>
  html = "<%= j render('health/services/service_row', service: @service) %>"
  $('.jServicesList [data-id="<%= @service.id %>"]').replaceWith(html)
  $('.modal:visible .close').trigger('click')

<% end %>