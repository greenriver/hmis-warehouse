<% if @release_form.errors.any? %>
  $('.release-form').html "<%=j render 'form' %>"
<% else %>
  $('#ajax-modal').modal('hide')
  window.location.reload()
<% end %>