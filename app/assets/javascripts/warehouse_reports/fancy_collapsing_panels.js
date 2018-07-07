$('.panel-collapsible .panel-heading').on('click', '.toggle', function(e) {
  var $button = $(e.currentTarget);
  var $collapsed_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-right');
  var $expanded_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-down');
  // console.log($button.hasClass('collapsed'));
  if($button.hasClass('collapsed')) {
    $collapsed_arrow.addClass('hide');
    $expanded_arrow.removeClass('hide');
  }
  else {
    // console.log($collapsed_arrow, $expanded_arrow);
    $collapsed_arrow.removeClass('hide');
    $expanded_arrow.addClass('hide');
  }
});
