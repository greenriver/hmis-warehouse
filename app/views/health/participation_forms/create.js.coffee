<% if @participation_form.errors.any? %>
  $('.participation-form').html "<%=j render 'form' %>"
<% else %>
  $('#ajax-modal').modal('hide')
  window.location.reload()
<% end %>