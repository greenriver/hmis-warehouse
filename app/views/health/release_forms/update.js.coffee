<% if @release_form.errors.any? %>
  $('.release-form').html "<%=j render 'form' %>"
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>