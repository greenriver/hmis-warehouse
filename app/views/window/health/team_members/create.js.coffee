<% if @new_member.errors.any? %>
  $('form#new_member .alert.alert-danger').remove()
  $('form#new_member').prepend('<div class="alert alert-danger"><%= @new_member.errors.full_messages.join(', ') %></div>')
<% else %>
  html = "<%= j render('window/health/team_members/team_member', member: @new_member, restore: false, delete: true) %>"
  $container = $('.health__team-members')
  $container.append(html)
  $('.modal:visible .close').trigger('click')
  $container.find('.no-data').remove()
  <% form = nil %>
  <% simple_form_for @careplan, url: polymorphic_path(careplan_path_generator, id: @careplan) do |f| %>
    <% form = f %>
  <% end %>
  $signaturesContainer = $('.careplan-signatures')
  $signaturesContainer.html("<%= j render('window/health/careplans/careplan_form_signatures', f: form) %>")
  $('.select2').select2();
<% end %>
