<% if @service.errors.any? %>
  alert "<%= @service.errors.full_messages.join(', ') %>"
<% else %>
  $('.jServicesList [data-id="<%= @service.id %>"]').remove()
  $('.modal:visible .close').trigger('click')
<% end %>