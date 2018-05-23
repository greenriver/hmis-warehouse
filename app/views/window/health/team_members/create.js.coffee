<% if @new_member.errors.any? %>
  $('form#new_member .alert.alert-danger').remove()
  $('form#new_member').prepend('<div class="alert alert-danger"><%= @new_member.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/team_members/team_member', member: @new_member, restore: false) %>"
  $('.health__team-members').append(html)
  $('.modal:visible .close').trigger('click')
  
<% end %>