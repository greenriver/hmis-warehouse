$('.panel-collapsible .panel-heading').on('click', '.toggle', function(e) {
  var $button = $(e.currentTarget);
  var $collapsed_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-right');
  var $expanded_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-down');
  var collapsible_parent_id = $(e.currentTarget).data('parent');
  var $all_down_arrows = $(collapsible_parent_id).find('.icon-arrow-circled-down');
  var $all_side_arrows = $(collapsible_parent_id).find('.icon-arrow-circled-right');
  // console.log($button.hasClass('collapsed'));
  if($button.hasClass('collapsed')) {
    $all_down_arrows.addClass('hide');
    $all_side_arrows.removeClass('hide');
    $collapsed_arrow.addClass('hide');
    $expanded_arrow.removeClass('hide');
  }
  else {
    // console.log($collapsed_arrow, $expanded_arrow);
    $all_side_arrows.removeClass('hide');
    $collapsed_arrow.removeClass('hide');
    $expanded_arrow.addClass('hide');
  }
});
