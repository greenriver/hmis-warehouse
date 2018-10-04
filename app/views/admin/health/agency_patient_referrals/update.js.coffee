<% if @error.present? %>
  alert "<%= @patient_referral.errors.full_messages.join(', ') %>"
<% else %>
  $row = $(".pr-<%= @patient_referral.id %>")
  $row.addClass 'highlight'
  $button_block = $row.find('.jClaimButtons')
  url = "<%= admin_health_agency_patient_referral_claim_buttons_path(agency_patient_referral_id: @patient_referral.id) %>"
  $.get url, (data) =>
    $button_block.html(data)

  setTimeout =>
    $row.removeClass('highlight')
  , 2000
<% end %>