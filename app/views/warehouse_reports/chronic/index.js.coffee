$('.report-listing').html "<%=j render 'reports' %>"

$(".report-listing tr").first().addClass 'highlight'