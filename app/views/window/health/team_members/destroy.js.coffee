<% if @member.errors.any? %>
  alert "<%= @member.errors.full_messages.join(', ') %>"
<% else %>
  $('.jTeamMember[data-id="<%= @member.id %>"]').remove()
  $container = $('.health__team-members')
  if not $container.find('.jTeamMember').length
    $container.append " <p class='no-data'>No team members currently.</p> "
<% end %>
