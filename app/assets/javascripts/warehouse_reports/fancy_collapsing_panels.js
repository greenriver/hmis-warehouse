$('.panel-collapsible .panel-collapse').on('show.bs.collapse hide.bs.collapse', function(e) {
  var state = e.handleObj.type === 'show' ? 'down' : 'right'
  var $parent = $(this).parent()
  $parent
    .find('.j-toggle-arrow')
    .removeClass()
    .addClass('icon-arrow-circled-' + state + ' j-toggle-arrow')
  $parent
    .find('input')
    .first()
    .focus()
})
