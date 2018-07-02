<% if @member.errors.any? %>
  $('form#edit_member .alert.alert-danger').remove()
  $('form#edit_member').prepend('<div class="alert alert-danger"><%= @member.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/patient_team_members/team_member', member: @member) %>"
  $container = $('.health__team-members')
  rowId = '<%= "#team-member-#{@member.id}" %>'
  $row = $container.find(rowId)
  $(html).insertAfter(rowId)
  $row.remove()
  $('.modal:visible .close').trigger('click')
<% end %>