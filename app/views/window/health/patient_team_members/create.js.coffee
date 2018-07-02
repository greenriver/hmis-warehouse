<% if @new_member.errors.any? %>
  $('form#new_member .alert.alert-danger').remove()
  $('form#new_member').prepend('<div class="alert alert-danger"><%= @new_member.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/patient_team_members/team_member', member: @new_member) %>"
  $container = $('.health__team-members')
  $container.append(html)
  $container.parent().find('.no-data').remove()
  $('.modal:visible .close').trigger('click')
<% end %>