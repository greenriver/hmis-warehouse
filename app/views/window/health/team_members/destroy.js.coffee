<% if @member.errors.any? %>
  alert "<%= @member.errors.full_messages.join(', ') %>"
<% else %>
  $('.jTeamMember[data-id="<%= @member.id %>"]').remove()  
<% end %>