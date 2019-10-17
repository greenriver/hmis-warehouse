<% if @help.errors.any? %>
  $('.help-form').html "<%=j render 'form' %>"
  $('.jSwitcher').trigger('change');
<% else %>
  $('#pjax-modal').modal('hide')
  window.location.reload()
<% end %>