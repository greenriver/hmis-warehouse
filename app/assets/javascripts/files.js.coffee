$(document).on 'change', '#grda_warehouse_client_file_tag_list', (e) ->
  file_types = $('#grda_warehouse_client_file_tag_list option:selected')
  fields = $('.consent-form-fields')

  tags = (type.value for type in file_types)

  if 'Consent Form' in tags
    fields.show()
  else
    fields.hide()

$('#grda_warehouse_client_file_tag_list').trigger('change')