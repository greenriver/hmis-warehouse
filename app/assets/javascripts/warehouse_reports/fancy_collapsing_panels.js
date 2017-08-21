$('.panel-collapsible .panel-heading').on('click', '.toggle', function(e) {
  var $button = $(e.currentTarget);
  var $collapsed_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-right');
  var $expanded_arrow = $(e.currentTarget).closest('.panel-heading').find('.icon-arrow-circled-down');
  console.log($collapsed_arrow);
  if($button.hasClass('collapsed')) {
    $collapsed_arrow.addClass('hide');
    $expanded_arrow.removeClass('hide');
  }
  else {
    $collapsed_arrow.removeClass('hide');
    $expanded_arrow.addClass('hide');
  }
});