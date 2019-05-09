$('.panel-collapsible .panel-collapse').on('show.bs.collapse hide.bs.collapse', function(e) {
  const state = e.handleObj.type === 'show' ? 'down' : 'right'
  $(this)
    .parent()
    .find('.j-toggle-arrow')
    .removeClass()
    .addClass('icon-arrow-circled-' + state + ' j-toggle-arrow')
})
