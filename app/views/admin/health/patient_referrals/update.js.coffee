<% if @patient_referral.errors.any? %>
  alert "<%= @patient_referral.errors.full_messages.join(', ') %>"
<% else %>
  $(".pr-<%= @patient_referral.id %>").addClass 'highlight'

  setTimeout ->
    $(".pr-<%= @patient_referral.id %>").removeClass('highlight')
  , 2000
<% end %>