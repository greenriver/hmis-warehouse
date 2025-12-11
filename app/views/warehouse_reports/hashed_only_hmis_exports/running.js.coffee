$('.report-listing').html "<%=j render_paginated_list(scope: @exports, item_name: 'export', list_partial: 'list', url: warehouse_reports_hashed_only_hmis_exports_path) %>"
