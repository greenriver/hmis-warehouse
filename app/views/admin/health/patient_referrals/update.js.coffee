<% if @patient_referral.errors.any? %>
  alert "<%= @patient_referral.errors.full_messages.join(', ') %>"
<% else %>
  $row = $(".j-pr-<%= @patient_referral.id %>")
  $rowContent = $row.find('.jPatientReferral')
  $rowContent.addClass 'highlight'

  setTimeout ->
    $rowContent.removeClass('highlight')
  , 2000
<% end %>
