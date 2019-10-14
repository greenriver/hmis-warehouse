<% if @member.errors.any? %>
  alert "<%= @member.errors.full_messages.join(', ') %>"
<% else %>
  rowId = '<%= "#team-member-#{@member.id}" %>'
  $(rowId).remove()
  $container = $('.health__team-members')
  if not $container.find('.jTeamMember').length
    $container.parent().append(" <p class='no-data'>No team members currently.</p> ")
<% end %>