html = "<%= j render('health/he/locations/table', readonly: false) %>"
$container = $('.jLocations')
$container.html(html)
$('#ajax-modal').modal('hide')