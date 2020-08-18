<% if @result.errors.any? %>
  $('.result-form').html "<%=j render 'form' %>"
  $('.result-form .alert.alert-danger').remove()
  $('.result-form').prepend('<div class="alert alert-danger"><%= @result.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('health/he/results/table', readonly: false) %>"
  $container = $('.jResults')
  $container.html(html)
  $('#pjax-modal').modal('hide')
<% end %>

