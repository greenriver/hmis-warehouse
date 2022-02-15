<% if @participation_form.errors.any? %>
$('.participation-form').html "<%=j render 'form', form_url: client_health_participation_form_path(client_id: @client.id, id: @participation_form.id) %>"
<% else %>
$('#ajax-modal').modal('hide')
window.location.replace('<%= client_health_patient_index_path(@client) %>')
<% end %>