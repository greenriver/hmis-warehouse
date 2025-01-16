<% if notification_configuration.errors.any? %>
  $('.notification-configuration').html "<%=j render 'form' %>"
<% else %>
  $('#ajax-modal').modal('hide')
<% end %>
