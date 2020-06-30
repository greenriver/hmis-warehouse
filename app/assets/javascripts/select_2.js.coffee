#= require ./namespace
App.select2 ||= {}

App.select2.init = () =>
  $('.select2').each () ->
    $select = $(this)
    $select.select2()
    # Add select all functionality if has `multiple` attribute
    if this.hasAttribute('multiple')
      App.select2.initToggleSelectAll($select)
    # CoCs get special functionality
    if this.classList.contains('select2-id-when-selected')
      App.select2.initIdWhenSelected($select)
    if this.classList.contains('select2-parenthetical-when-selected')
      App.select2.initParentheticalWhenSelected($select)

App.select2.initToggleSelectAll = ($select) =>
  # If we made any changes manually, and there are any selected, set the link to "select none"
  updateSelectAllState = () =>
    $selectAllLink = $formGroup.find('.select2-select-all')
    allSelected = $selectAllLink.data('selected')
    $selectAllLink.data('selected', !allSelected)
    if $formGroup.find('select').val() == 0 || $select.select2('data').length == 0
      classAction = 'removeClass'
      html = """
        <span class='mr-2'>Select all</span>
      """
    else# if $select.select2('data').length < $select.find('option').length
      classAction = 'addClass'
      html = """
        <span class='mr-2'>Select none</span>
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
    """
    if !allSelected
      classAction = 'addClass'
      html = """
        <span class='mr-2'>Select none</span>
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
  $label = $formGroup.find('> label')
  $labelWrapper = $("<div class='select2__label-wrapper'></div>")
  allOrNone = 'all'
  $labelWrapper.append $("""
    <div class="select2-select-all j-select2-select-all" data-selected="false" >
      <span class='mr-2'>Select all</span>
    </div>
  """)
  $label.prependTo $labelWrapper
  $formGroup.prepend $labelWrapper
  $select2Container = $select.next('.select2-container')
  $select.closest('.form-group').on 'click', '.j-select2-select-all', (event)=>
    toggleSelectAll()
  $select.on 'select2:select', (event)=>
    updateSelectAllState()
  $select.on 'select2:unselect', (event)=>
    updateSelectAllState()
  # initial state
  updateSelectAllState()

App.select2.initIdWhenSelected = ($select) =>
  $select.select2(
    {
      templateSelection: (selected) =>
        if !selected.id
          return selected.text
        # use the code to keep the select smaller
        return selected.id
    }
  )

App.select2.initParentheticalWhenSelected = ($select) =>
  $select.select2(
    {
      templateSelection: (selected) =>
        if !selected.id
          return selected.text
        # use the parenthetical text to keep the select smaller
        regex = /\((.+?)\)/
        matched = selected.text.match(regex)
        if !matched.length == 2
          return selected.text
        return matched[1]
    }
  )

