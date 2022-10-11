$('.panel-collapsible .panel-collapse').on('show.bs.collapse hide.bs.collapse', function(e) {
  var state = e.handleObj.type === 'show' ? 'down' : 'right'
  var $parent = $(this).parent()
  var arrow_icon = $parent.data('arrow-icon');
  $parent
    .find('.j-toggle-arrow')
    .removeClass()
    .addClass(arrow_icon + '-' + state + ' j-toggle-arrow')
  $parent
    .find('input')
    .first()
    .focus()
  $parent
    .find('.j-toggle-text')
    .toggleClass(['hide', 'show'])
})
