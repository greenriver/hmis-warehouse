#= require namespace
App.init = ->
  $('abbr').tooltip();
  $('[data-toggle="tooltip"]').tooltip();
  $('[data-toggle="popover"]').popover();
  $('.select2').each () ->
    $select = $(this)
    $formGroup = $select.closest('.form-group')
    $formGroup.addClass('select2-wrapper')
    $select.select2()
    if this.getAttribute('allowSelectAll')
      $select2Container = $select.next('.select2-container')
      $select2Container.append $("""
        <div class="select2-select-all j-select2-select-all" data-selected="false" >
          Select all
        </div>
      """)
      $select.on 'select2:unselect', () =>
        if $select2Container.hasClass('all-selected')
          $select2Container.removeClass('all-selected')
          toggleSelectAll(false)
      $select.closest('.form-group').on 'click', '.j-select2-select-all', (event)=>
        toggleSelectAll()

      toggleSelectAll = (updateOptions=true) =>
        $selectAllLink = $formGroup.find('.select2-select-all')
        allSelected = $selectAllLink.data('selected')
        $selectAllLink.data('selected', !allSelected)
        classAction = 'removeClass'
        html = 'Select all'
        if !allSelected
          classAction = 'addClass'
          html = 'Select none'
          $select2Container.find('.select2-selection').append """
            <div class='select2-selection__choice select2-select-all-message'>
              <span class='j-select2-select-all' role='presentation'>×</span>
              All items selected
            </div>
          """
        else
          $select2Container.find('.select2-select-all-message').remove()
        $selectAllLink.html(html)
        $select2Container[classAction]('all-selected')
        if (updateOptions)
          $select.find('option').prop("selected", !allSelected);
        $select.trigger('change')
        $select.select2('close')

  $.fn.datepicker.defaults.format = "M d, yyyy";
  $('.nav-tabs .active-tab').on 'click', 'a', (e)->
    e.preventDefault()
  $('.colorpicker').minicolors(theme: 'bootstrap')
  $(document).on 'click', '.jCheckAll', (e) ->
    id = $(this).attr('id')
    checked = $(this).prop('checked')
    $('input.' + id).prop('checked', checked)
  return true


# TODO may also need to do on pjax_modal change
$ ->
  App.init()
  $('.datepicker.enable-on-load, .date_picker.enable-on-load')
    .prop('disabled', false)
    .datepicker()

  poller = $('[data-poll-every]').first()
  if poller.length > 0
    setInterval ->
      poller.click()
    , poller.data('poll-every')*1000
