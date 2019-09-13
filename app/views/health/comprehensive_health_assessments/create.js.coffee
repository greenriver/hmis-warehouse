<% if @cha.errors.any? %>
  $('.cha-form').html "<%=j render 'form' %>"
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>