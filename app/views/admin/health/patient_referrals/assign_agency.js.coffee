<% if @error.present? %>
  alert "<%= @error %>"
<% else %>
  $row = $(".j-pr-<%= @patient_referral.id %>")
  $rowContent = $row.find('.jPatientReferral')

  # If this is a re-assignment, just reload the page
  is_assignment_str = "<%= @patient_referral.assigned_agency.present? %>"
  if ($rowContent.hasClass 'jPatientReferralAssigned') && (is_assignment_str == "true")
    location.reload()
    return

  success_message = "<%= @success %>"
  if (success_message)
    $('#notice').html("<div class='alert alert-info'>#{success_message}</div>")

  # If this is an initial assignment or an un-assignment, hide the referral
  $rowContent.addClass 'highlight'

  setTimeout ->
    $rowContent.removeClass('highlight').slideUp(400)
    # reload if we're out of patient referrals
    if $('.jPatientReferral:visible').length == 1
      location.reload()
  , 1200

<% end %>
