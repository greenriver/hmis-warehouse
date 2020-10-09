<% if @help.errors.any? %>
  $('.help-form').html "<%=j render 'form' %>"
  $('.jSwitcher').trigger('change');
<% else %>
  $('#ajax-modal').modal('hide')
<% end %>
