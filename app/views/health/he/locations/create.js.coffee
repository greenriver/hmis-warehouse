<% if @location.errors.any? %>
  $('.location-form').html "<%=j render 'form' %>"
  $('.location-form .alert.alert-danger').remove()
  $('.location-form').prepend('<div class="alert alert-danger"><%= @location.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('health/he/locations/table', readonly: false) %>"
  $container = $('.jLocations')
  $container.html(html)
  $('#pjax-modal').modal('hide')
<% end %>

