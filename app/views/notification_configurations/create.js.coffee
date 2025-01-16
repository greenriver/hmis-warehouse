<% if notification_configuration.errors.any? %>
  console.log(<%= notification_configuration.errors.inspect %>)
  $('.notification-configuration').html "<%=j render 'form' %>"
<% else %>
  $('#ajax-modal').modal('hide')
  // Figure out how to reload the table
<% end %>
