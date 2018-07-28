<% if @member.errors.any? %>
  alert "<%= @member.errors.full_messages.join(', ') %>"
<% else %>
  $('.jTeamMember[data-id="<%= @member.id %>"]').remove()
  $container = $('.health__team-members')
  if not $container.find('.jTeamMember').length
    $container.append " <div class='j-no-data'><p class='ml-3'>No team members currently.</p></div> "
  <% form = nil %>
  <% simple_form_for @careplan, url: polymorphic_path(careplan_path_generator, id: @careplan) do |f| %>
    <% form = f %>
  <% end %>
  $signaturesContainer = $('.careplan-signatures')
  $signaturesContainer.html("<%= j render('window/health/careplans/careplan_form_signatures', f: form) %>")
  $('.select2').select2();
<% end %>
