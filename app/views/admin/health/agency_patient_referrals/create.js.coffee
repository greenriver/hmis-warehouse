<% if @error.present? %>
  alert "<%= @patient_referral.errors.full_messages.join(', ') %>"
<% else %>
  $row = $(".j-pr-<%= @patient_referral.id %>")
  $rowContent = $row.find('.jPatientReferral')
  $rowContent.addClass 'highlight'
  $button_block = $row.find('.jClaimButtons')
  url = "<%= admin_health_agency_patient_referral_claim_buttons_path(agency_patient_referral_id: @patient_referral.id) %>"
  $.get url, (data) =>
    $button_block.html('').html(data)

  setTimeout =>
    $rowContent.removeClass('highlight')
  , 2000
<% end %>
