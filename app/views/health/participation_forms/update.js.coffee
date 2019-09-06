<% if @participation_form.errors.any? %>
  $('.participation-form').html "<%=j render 'form' %>"
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>