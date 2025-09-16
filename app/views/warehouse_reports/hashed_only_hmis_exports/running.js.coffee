$('.report-listing').html "<%=j render_paginated_list(scope: @exports, item_name: 'export', list_partial: 'list') %>"
