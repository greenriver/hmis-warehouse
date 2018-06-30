<% if @member.errors.any? %>
  $('form#edit_member .alert.alert-danger').remove()
  $('form#edit_member').prepend('<div class="alert alert-danger"><%= @member.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/team_members/team_member', member: @member, restore: false, delete: true) %>"
  $container = $('.health__team-members')
  rowSelector = '<%= ".jTeamMember[data-id=#{@member.id}]" %>'
  $row = $container.find(rowSelector)
  $(html).insertAfter(rowSelector)
  $row.remove()
  $('.modal:visible .close').trigger('click')
  <% form = nil %>
  <% simple_form_for @careplan, url: polymorphic_path(careplan_path_generator, id: @careplan) do |f| %>
    <% form = f %>
  <% end %>
  $signaturesContainer = $('.careplan-signatures')
  $signaturesContainer.html("<%= j render('window/health/careplans/careplan_form_signatures', f: form) %>")
  $('.select2').select2();
<% end %>