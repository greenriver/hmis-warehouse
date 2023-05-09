<% if @qa.errors.any? %>
$('.jQaForm').replaceWith "<%=j render('edit', qa: @qa) %>"
$('.jQaForm .alert.alert-danger').remove()
$('.jQaForm').prepend('<div class="alert alert-danger"><%= @qa.errors.full_messages.join(', ') %></div>')
<% else %>
html = "<%= j render('health/sdh_case_management_notes/activities', qa: @qa) %>"
$('.modal:visible .close').trigger('click')
$container = $('.jActivityList')
$container.replaceWith(html)
<% end %>


