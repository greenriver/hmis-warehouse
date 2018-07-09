<% if @release_form.errors.any? %>
  $('.release-form').html "<%=j render 'form' %>"
  $('.release-form .alert.alert-danger').remove()
  $('.release-form').prepend('<div class="alert alert-danger"><%= @release_form.errors.full_messages.join(', ') %></div>')
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>