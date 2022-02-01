<% if @participation_form.errors.any? %>
$('.release-form').html "<%=j render 'form', form_url: client_health_participation_forms_path(@client.id) %>"
<% else %>
$('#ajax-modal').modal('hide')
window.location.replace('<%= client_health_patient_index_path(@client) %>')
<% end %>
