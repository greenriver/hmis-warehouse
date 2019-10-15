<% if @help.errors.any? %>
  $('.help-form').html "<%=j render 'form' %>"
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>