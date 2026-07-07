<% if @file.errors.any? %>
  alert "<%= @file.errors.full_messages.join(', ') %>"
<% else %>
  $(".client-file-<%= @file.id %>").addClass 'bg-warning-subtle'
  $(".client-file-<%= @file.id %> .consent-status-badges").html("<%= escape_javascript(render('clients/files/consent_badges', file: @file)) %>")

  setTimeout ->
    $(".client-file-<%= @file.id %>").removeClass('bg-warning-subtle')
  , 2000
<% end %>
