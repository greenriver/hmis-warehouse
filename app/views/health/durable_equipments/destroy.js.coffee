<% if @equipment.errors.any? %>
  alert "<%= @equipment.errors.full_messages.join(', ') %>"
<% else %>
  $('.jEquipmentList [data-id="<%= @equipment.id %>"]').remove()
  $('.modal:visible .close').trigger('click')
<% end %>