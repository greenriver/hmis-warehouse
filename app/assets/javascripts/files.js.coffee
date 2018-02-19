$(document).on 'change', '.jFileTags', (e) ->
  file_types = $('.jFileTags option:selected')
  tags = (type.value for type in file_types)
  console.log 'test'
  consent_forms = 'ttt'
  console.log 'test'
  if 'Consent Form' in tags or 'HAN Release' in tags
    $('.consent-form-fields').removeClass('hidden')
  else
    $('.consent-form-fields').addClass('hidden')
  if 'Verification of Disability' in tags or 'Disability Verification' in tags
    $('.disability-warning').removeClass('hidden')
  else
    $('.disability-warning').addClass('hidden')

$('.jFileTags').trigger('change')


$('.jThumb').each (e) ->
  thumb = this
  file_id = $(this).data('file')
  url_base = window.location.pathname + '/' + file_id
  url = url_base + '/has_thumb'
  $.get url, (data, textStatus, jqXHR) ->
    thumb_url = url_base + '/thumb'
    preview_url = url_base + '/preview'
    if(textStatus == 'success')
      link = '<a href="' + preview_url + '" target="_blank"><img src="' + thumb_url + '" class="file-thumbnail" /></a>'
    else 
      link = '<a href="' + preview_url + '" target="_blank"><i class="icon-eye btn btn-secondary btn-lg"/></a>'
    $(thumb).html(link)
