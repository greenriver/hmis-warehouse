$('.jThumb').each (e) ->
  thumb = this
  file_id = $(this).data('file')
  url_base = window.location.pathname + '/' + file_id
  url = url_base + '/has_thumb'
  $.get url, (data, textStatus, jqXHR) ->
    thumb_url = url_base + '/thumb'
    preview_url = url_base + '/preview'
    if(textStatus == 'success')
      link = '<a href="' + preview_url + '" target="_blank"><div style="background-image: url(' + thumb_url + ')" class="file-thumbnail file-thumbnail--image"></div></a>'
    else
      link = '<a href="' + preview_url + '" target="_blank"><div class="file-thumbnail"></div></a>'
    $(thumb).html(link)

$(document).on 'change', '.jFileTag', (e) ->
  # Show notes
  if $(this).data('toggle') == 'popover'
    $('.jFileTag').not(this).popover('hide')
    $(this).popover('show')
  else
    $('.jFileTag').popover('hide')

  # Show consent form confirmed
  if $(this).data('consent')
    $('.consent-form-fields').removeClass('hidden')
  else
    $('.consent-form-fields').addClass('hidden')

$(document).on 'change', '.jDownload', (e) ->
  ids = $('.jDownload:checked').map ->
    $(this).val()
  $('tr.active').removeClass('active')
  $('.jDownload:checked').each ->
    $(this).closest('tr').addClass('active')
  $('.jDownloadIDs').attr('value', ids.get())
  if $('.jDownload:checked').val()?
    $('.jDownloadButton').removeAttr('disabled')
  else
    $('.jDownloadButton').attr('disabled', 'disabled')
$('.jDownload').trigger('change')
