<% if @error.present? %>
  alert "<%= @error %>"
<% else %>
  $(".pr-<%= @patient_referral.id %>").addClass 'highlight'

  setTimeout ->
    $(".pr-<%= @patient_referral.id %>").removeClass('highlight')
    $(".pr-<%= @patient_referral.id %>").slideUp(400)
    # reload if we're out of patient referrals
    if $('.jPatientReferral:visible').length == 1
      location.reload()
  , 1200
<% end %>