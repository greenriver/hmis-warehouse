<% if @cha.errors.any? %>
  $('.cha-form').html "<%=j render 'form' %>"
<% else %>
  $('#ajax-modal').modal('hide')
  window.location.reload()
<% end %>