html = "<%= j render('health/sdh_case_management_notes/activities', qa: @qa) %>"
$('.modal:visible .close').trigger('click')
$container = $('.jActivityList')
$container.replaceWith(html)
