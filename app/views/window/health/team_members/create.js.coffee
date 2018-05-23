<% if @new_member.errors.any? %>
  $('form#new_member').prepend('<div class="alert alert-danger"><%= @new_member.errors.full_messages.join(', ') %></div>')
<% else %>
  $('.modal:visible .close').trigger('click')
<% end %>