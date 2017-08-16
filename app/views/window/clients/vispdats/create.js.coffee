<% if @vispdat.present? %>
  $('.vispdat-table tbody').prepend "<%=j render partial: 'vispdat_row', object: @vispdat, as: :vispdat %>"

  $("#vispdat-<%= @vispdat.id %>").addClass 'highlight'
<% else %>
  alert "<%= @client.full_name %> already has a VI-SPDAT in progress. Please complete that one or delete it before starting a new VI-SPDAT"
<% end %>
