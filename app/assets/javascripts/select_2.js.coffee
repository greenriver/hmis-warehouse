#= require ./namespace
App.select2 ||= {}

App.select2.init = () =>
  $('.select2').each () ->
    $select = $(this)
    $select.select2()
    # Add select all functionality if has `multiple` attribute
    if this.hasAttribute('multiple')
      App.select2.initToggleSelectAll($select)

App.select2.initToggleSelectAll = ($select) =>
  # If we made any changes manually, and there are any selected, set the link to "select none"
  updateSelectAllState = () =>
    $selectAllLink = $formGroup.find('.select2-select-all')
    allSelected = $selectAllLink.data('selected')
    $selectAllLink.data('selected', !allSelected)

    if $select.select2('data').length == 0
      classAction = 'removeClass'
      html = """
        <span class='mr-2'>Select all</span>
        <i class='icon-checkbox-checked' />
      """
    else# if $select.select2('data').length < $select.find('option').length
      classAction = 'addClass'
      html = """
        <span class='mr-2'>Select none</span>
        <i class='icon-checkbox-unchecked' />
      """
    $selectAllLink.html(html)
    $select2Container[classAction]('all-selected')
    $select.trigger('change')
    $select.select2('close')

  toggleSelectAll = (updateOptions=true, options={}) =>
    $selectAllLink = $formGroup.find('.select2-select-all')
    allSelected = $selectAllLink.data('selected')
    $selectAllLink.data('selected', !allSelected)
    classAction = 'removeClass'
    html = """
      <span class='mr-2'>Select all</span>
      <i class='icon-checkbox-checked' />
    """
    if !allSelected
      classAction = 'addClass'
      html = """
        <span class='mr-2'>Select none</span>
        <i class='icon-checkbox-unchecked' />
      """
    $selectAllLink.html(html)
    $select2Container[classAction]('all-selected')
    if (updateOptions)
      $select.find('option').prop("selected", !allSelected);
    $select.trigger('change')
    $select.select2('close')

  # Init here
  $formGroup = $select.closest('.form-group')
  $formGroup.addClass('select2-wrapper')
  $select2Container = $select.next('.select2-container')
  $select2Container.append $("""
    <div class="select2-select-all j-select2-select-all" data-selected="false" >
      <span class='mr-2'>Select all</span>
      <i class='icon-checkbox-checked' />
    </div>
  """)
  $select.closest('.form-group').on 'click', '.j-select2-select-all', (event)=>
    toggleSelectAll()
  $select.on 'select2:select', (event)=>
    updateSelectAllState()
  $select.on 'select2:unselect', (event)=>
    updateSelectAllState()
  # initial state
  updateSelectAllState()



