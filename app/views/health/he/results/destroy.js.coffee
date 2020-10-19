html = "<%= j render('health/he/results/table', readonly: false) %>"
$container = $('.jResults')
$container.html(html)
$('#ajax-modal').modal('hide')