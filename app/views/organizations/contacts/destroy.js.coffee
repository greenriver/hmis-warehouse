<% if @error.present? %>
  console.log('error')
<% else %>
  url = "<%= new_organization_contact_path(@entity, remote_submit: true, layout: false) %>"
  $.get url, (data) =>
    $('.jModalReplaceMe').replaceWith(data);

  # setTimeout =>
  #   $row.removeClass('highlight')
  # , 2000
<% end %>