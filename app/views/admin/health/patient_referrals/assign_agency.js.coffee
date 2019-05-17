<% if @error.present? %>
  alert "<%= @error %>"
<% else %>
  $row = $(".j-pr-<%= @patient_referral.id %>")
  $rowContent = $row.find('.jPatientReferral')
  $rowContent.addClass 'highlight'

  setTimeout ->
    $rowContent.removeClass('highlight').slideUp(400)
    # reload if we're out of patient referrals
    if $('.jPatientReferral:visible').length == 1
      location.reload()
  , 1200

<% end %>
