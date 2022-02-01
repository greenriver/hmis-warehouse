<% if @release_form.errors.any? %>
  $('.release-form').html "<%=j render 'form', form_url: client_health_release_form_path(client_id: @client.id, id: @release_form.id) %>"
<% else %>
  $('#ajax-modal').modal('hide')
  window.location.replace('<%= client_health_patient_index_path(@client) %>')
<% end %>