class App.Cohorts.Cohort
  constructor: (options) ->
    @wrapper_selector = options['wrapper_selector']
    @table_selector = options['table_selector']
    @batch_size = options['batch_size']
    # @static_column_count = options['static_column_count']
    @client_count = options['client_count']
    @sort_direction = options['sort_direction']
    @column_order = options['column_order']
    @column_headers = options['column_headers']
    @column_options = options['column_options']
    @column_widths = options['column_widths']
    @size_toggle_class = options['size_toggle_class']
    @include_inactive = options['include_inactive']
    @client_path = options['client_path']
    @client_row_class = options['client_row_class']
    @loading_selector = options['loading_selector']
    @cohort_client_form_selector = options['cohort_client_form_selector']
    @cohort_value_hidden_selector = options['cohort_value_hidden_selector']
    @check_url = options['check_url']
    @input_selector = options['input_selector']
    @updated_ats = options['updated_ats']
    @search_selector = options['search_selector']
    @search_actions_selector = options['search_actions_selector']
    @population = options['population']

    # Testing
    # @client_count = 15
    # @batch_size = 5

    @pages = Math.round(@client_count/@batch_size)

    @current_page = 0
    @raw_data = []

    @initialize_grid()

    @load_pages()
    @resize_columns()
    # @listen_for_page_resize()

  initialize_grid: () =>
    direction = true
    if @sort_direction == 'desc'
      direction = false
    @initial_sort = {column: 1, sortOrder: direction}
    @current_sort = Object.assign({}, @initial_sort)
    @set_grid_column_headers()

    @grid_options = {
      columnDefs: @grid_column_headers,
      enableSorting: true,
      enableFilter: true,
      singleClickEdit: true,
      onCellEditingStarted: (e) ->
        console.log "cellEditingStarted", e
      onCellEditingStopped: (e) ->
        console.log "cellEditingStopped", e
      # frameworkComponents:
      #   htmlRenderer: @htmlRenderer,
      components:
          dateCellEditor: DateCellEditor,
          dateCellRenderer: DateCellRenderer,
          checkboxCellEditor: CheckboxCellEditor,
          checkboxCellRenderer: CheckboxCellRenderer

    }
    @table = new agGrid.Grid($(@table_selector)[0], @grid_options)

    # // specify the columns
    #   var columnDefs = [
    #     {headerName: "Make", field: "make"},
    #     {headerName: "Model", field: "model"},
    #     {headerName: "Price", field: "price"}
    #   ];
    #   // specify the data
    #   var rowData = [
    #     {make: "Toyota", model: "Celica", price: 35000},
    #     {make: "Ford", model: "Mondeo", price: 32000},
    #     {make: "Porsche", model: "Boxter", price: 72000}
    #   ];
    #   // let the grid know which columns and what data to use
    #   var gridOptions = {
    #     columnDefs: columnDefs,
    #     rowData: rowData,
    #     enableSorting: true,
    #     enableFilter: true
    #   };
    #   // lookup the container we want the Grid to use
    #   var eGridDiv = document.querySelector('.jGrid');
    #   // create the grid passing in the div to use together with the columns & data we want to use
    #   new agGrid.Grid(eGridDiv, gridOptions);
    # @add_sort_options()
    # @table = new Handsontable $(@table_selector)[0],
    #   rowHeaders: true
    #   colHeaders: @column_headers
    #   correctFormat: true
    #   dateFormat: 'll'
    #   columns: @column_options
    #   fixedColumnsLeft: @static_column_count
    #   # manualColumnResize: @column_widths
    #   manualColumnResize: true
    #   rowHeights: 40
    #   sortIndicator: true
    #   search: true
    #   comments: true
    #   afterChange: @after_change
    #   beforeChange: @before_change
  resize_columns: =>
    @grid_options.columnApi.autoSizeColumns(@grid_options.columnApi.getAllColumns())

  set_grid_column_headers: =>
    console.log(@column_headers)
    @grid_column_headers = $.map @column_headers, (column) =>
      header = {
        headerName: column.headerName,
        field: column.field,
        editable: column.editable,
        tooltip: (params) ->
          params.data[params.colDef.field].comments
        valueGetter: (params) ->
          params.data[params.column.colId].value
        valueSetter: (params) ->
          if params.oldValue != params.newValue
            params.data[params.colDef.field].value = params.newValue
          else
            false
        onCellValueChanged: (params) =>
          cohort_client_id = params.data[params.colDef.field].cohort_client_id
          console.log 'changed', params.oldValue, 'to', params.newValue, cohort_client_id
          @after_edit(params.colDef.field, cohort_client_id, params.oldValue, params.newValue)
      }
      switch column.renderer
        when 'checkbox'
          header.cellRenderer = 'checkboxCellRenderer'
        when 'date'
          header.cellRenderer = 'dateCellRenderer'
        else
          header.cellRenderer = (params) =>
            params.getValue()

      header.pinned = column.pinned if column.pinned?

      switch column.renderer
        when 'date'
          header.cellEditor = 'dateCellEditor'
        when 'dropdown'
          header.cellEditor = 'agSelectCellEditor'
          header.cellEditorParams =
            values: column.available_options,
        when 'checkbox'
          header.cellEditor = 'checkboxCellEditor'
      if column.editable
        header.editable = column.editable
      else
        header.editable = (params) ->
          # console.log(params)
          params.data[params.column.colId].editable

      header

  # checkbox_renderer: (params) ->
  #   console.log(params)
  #   value = params.data[params.column.colId].value
  #   editable = params.data[params.column.colId].editable
  #   input = document.createElement("input")
  #   input.type = "checkbox";
  #   input.checked = params.value == true
  #   input.disabled = params.editable == false
  #   input

    # console.log(input)

    # html = '<input type="checkbox" value="1"'
    # html += ' checked="checked" ' if value == true
    # html += ' disabled="disabled" ' if editable == false
    # html += ' />'
    # html



  # add_sort_options:  =>
  #   for column in @column_options
  #     if column.type == 'checkbox'
  #       column.sortFunction = (sortOrder) =>
  #         (a, b) =>
  #           @sort_checkboxes(a, b, sortOrder)

  # This is to work around a bug in handsontable
  # https://github.com/handsontable/handsontable/issues/4047
  # sort_checkboxes: (a, b, sort_order) =>
  #   ret = if a[1] > b[1] then 1 else -1
  #   if sort_order
  #     if a[1] > b[1] then 1 else -1
  #   else
  #     if b[1] > a[1] then 1 else -1

  # after_change: (changes, source) =>
  #   if source == 'edit'
  #     @after_edit(changes)

  # before_change: (changes, source) =>
  #   if source == 'edit'
  #     @before_edit(changes)

  initialize_search_buttons: () =>
    $search_actions = $(@search_actions_selector)
    $back = $search_actions.find('.jSearchBack')
    $forward = $search_actions.find('.jSearchForward')
    $back.on 'click', (e) =>
      e.preventDefault()
      if @current_result == 0
        @current_result = @search_results.length - 1
      else
        prev = @current_result - 1
        @current_result = prev % @search_results.length
      @set_search_position()
    $forward.on 'click', (e) =>
      e.preventDefault()
      next = @current_result + 1
      @current_result = next % @search_results.length
      @set_search_position()

  move_to_current_result: () =>
    current = @search_results[@current_result]
    @table.scrollViewportTo(current.row, current.col)

  set_search_position: () =>
    $search_actions = $(@search_actions_selector)
    $search_status = $search_actions.find('.jSearchStatus')
    $search_status.text("#{@current_result + 1} of #{@search_results.length}")
    @move_to_current_result()

  update_search_navigation: () =>
    $search_actions = $(@search_actions_selector)
    $search_status = $search_actions.find('.jSearchStatus')
    @current_result = 0
    if @search_results? && @search_results.length > 0
      $search_actions.find('a').removeClass('disabled')
      $search_status.removeClass('hide')
      @set_search_position()
    else
      $search_actions.find('a').addClass('disabled')
      $search_status.addClass('hide')

  enable_searching: () =>
    searchField = $(@search_selector)[0]
    $(searchField).removeAttr('disabled')
    @initialize_search_buttons()
    Handsontable.dom.addEvent searchField, 'keyup', (e) =>
      search_string = '' + $(e.target).val()
      search_string = '' unless search_string.length > 2 # Don't match until we have 3 characters
      @search_results = @table.search.query(search_string)
      @update_search_navigation()
      @table.render()

  load_pages: () =>
    $(@loading_selector).removeClass('hidden')
    @load_page().then(() =>
      # When we're all done fetching...
      $(@loading_selector).addClass('hidden')
      # @format_data_for_table()
      # console.log @raw_data
      @grid_options.api.setRowData(@raw_data)
      # @reinitialize_js()
      # console.log(@table_data)

      # add the data to the table
      # @table.loadData(@raw_data)
      # @table.updateSettings
      #   cells: (row, col, prop) =>
      #     @format_cells(row, col, prop, @cell_metadata, @table)
      #   columnSorting: @initial_sort
      # @enable_searching()
      # @refresh_rate = 10000
      # setInterval @check_for_new_data, @refresh_rate

      # # console.log @raw_data

      # @set_rank_order()
      # @table.render()
    )

  # format_cells: (row, col, prop, metadata, table) ->
  #   cellProperties ={}
  #   # console.log row, col, prop,  metadata[row][col]
  #   return unless metadata? and metadata[row]?
  #   meta = metadata[row][col]
  #   row_meta = @raw_data[row].meta

  #   classes = []

  #   # mark read-only cells as such
  #   if meta?.editable == false
  #     cellProperties.readOnly = 'true'

  #   if meta.comments != null
  #     cellProperties.comment = {value: meta.comments}

  #   if meta.renderer == 'checkbox' || meta.column == 'notes' || meta.column == 'meta'
  #     classes.push('htCenter')
  #     classes.push('htMiddle')

  #   # mark inactive clients
  #   # if row_meta.activity == 'homeless_inactive'
  #   #   classes.push(row_meta.activity)

  #   # mark ineligible clients
  #   # if row_meta.ineligible == true
  #   #   classes.push('cohort_client_ineligible')

  #   cellProperties.className = classes.join(' ')
  #   return cellProperties

  # # deep_find: (obj, path) ->
  # #   paths = path.split('.')
  # #   current = obj
  # #   for i in [0...paths.length] by 1
  # #     # console.log current[paths[i]], paths[i]
  # #     if current[paths[i]] == undefined
  # #       undefined
  # #     else
  # #       current = current[paths[i]]
  # #   return current

  # # format_data_for_table: () =>
  # #   @table_data = $.map @raw_data, (row) =>
  # #     client = $.map @column_order, (column) =>
  # #       if row[column]['value'] == null
  # #         {column: ''}
  # #       else
  # #         {column: row[column]['value']}
  # #     [client]
  # #   @cell_metadata  = $.map @raw_data, (row) =>
  # #     client = $.map @column_order, (column) =>
  # #       m = row[column]
  # #       m['column'] = column
  # #       m
  # #     [client]

  load_page: () =>
    @current_page += 1
    url =  "#{@client_path}.json?page=#{@current_page}&per=#{@batch_size}&content=true"
    if @include_inactive
      url += "&inactive=true"
    if @population?
      url += "&population=#{@population}"

    if @current_page > @pages + 1
      return $.Deferred().resolve().promise()
    # Gather all the data first and then display it
    $.get({url: url}).done(@save_batch).then(@load_page)

  save_batch: (data, status) =>
    $.merge @raw_data, data
    percent_complete = Math.round(@current_page/@pages*100)
    $(@loading_selector).find('.percent-loaded').text("#{percent_complete}%")

  # reinitialize_js: () ->
  #   console.log('reinitialize_js', $('[data-toggle="tooltip"]'))
  #   $('[data-toggle="tooltip"]').tooltip()

  # listen_for_page_resize: () =>
  #   $(window).resize () =>
  #     @table.render()

  set_rank_order: () =>
    ids = for i in [0...@table.countRows()] by 1
      physical_index = @table.sortIndex[i][0]
      meta = @raw_data[physical_index].meta
      cohort_client_id = meta.cohort_client_id
    $('#rank_order').val(ids.join(','));
    $('.jReRank').removeClass('disabled');

  # before_edit: (changes, source) =>
  #   # an array of changes (only ever one for us)
  #   # changes[0][3] holds new value
  #   [row, col, original, current] = changes[0]
  #   return if original == current
  #   physical_index = @table.sortIndex[row][0]
  #   meta = @raw_data[physical_index].meta
  #   # We need the containing metadata for the column and our pattern always uses value
  #   cohort_column_column = col.replace('.value', '')
  #   column = @deep_find(@raw_data[physical_index], cohort_column_column)
  #   # If this is a date field, attempt to catch some common formats
  #   console.log
  #   if column.renderer == 'date' && current.length > 0
  #      current = moment(current).format('ll')
  #      @table.setDataAtRowProp(row, col, current)
  #      changes[0][3] = current

  after_edit: (column, cohort_client_id, old_value, new_value) =>
    console.log column, cohort_client_id, old_value, new_value

    field_name = "cohort_client[#{column}]"
    $form = $(@cohort_client_form_selector)
    proxy_field = $form.find('.proxy_field')
    $(proxy_field).attr('name', field_name).attr('value', new_value)
    url = $form.attr('action').replace('cohort_client_id', cohort_client_id)
    method = $form.attr("method");
    data = $form.serialize();
    options = {
      url : "#{url}.js",
      type: method,
      data: data,
      dataType: 'json'
    }

    $.ajax(options).complete (jqXHR) =>
      response = JSON.parse(jqXHR.responseText)
      alert_class = response.alert
      alert_text = response.message
      updated_at = response.updated_at
      cohort_client_id = response.cohort_client_id

      # Make note of successful update
      @updated_ats[cohort_client_id] = updated_at

      alert = "<div class='alert alert-#{alert_class}' style='position: fixed; top: 70px; z-index: 1500;'>#{alert_text}</div>"
      $('.utility .alert').remove()
      $('.utility').append(alert)
      $('.utility .alert').delay(2000).fadeOut(250)

  check_for_new_data: =>
    $.get @check_url, (data) =>
      # console.log 'checking', @updated_ats
      changed = false
      $.each data, (id, timestamp) =>
        if timestamp != @updated_ats[id]
          changed = true
          # console.log "didn't match", @updated_ats
          # console.log({client_id: id, server_timestamp: timestamp, client_timestamp: @updated_ats[id]})
          @reload_client(id)
      if changed
        # console.log 'Setting new updated ats'
        @updated_ats = data

  reload_client: (cohort_client_id) =>
    url =  "#{@client_path}.json?page=1&per=10&content=true&inactive=true&cohort_client_id=#{cohort_client_id}"
    $.get url, (data) =>
      client = data[0]
      # console.log client
      $.each @cell_metadata, (i, row) =>
        $.each row, (j, col) =>
          if col.cohort_client_id == +cohort_client_id
            if col.value != client[col.column].value
              # console.log i,j, client[col.column].value, @table_data[i][1], @raw_data[i][@column_order[j]]
              @cell_metadata[i][j].comments = client[col.column].comments
              @table_data[i][j] = client[col.column].value
              @raw_data[i][@column_order[j]].value = client[col.column].value
      # Preserve the sort order
      sort_column = @table.sortColumn
      sort_direction = @table.sortOrder
      sorting = {column: sort_column, sortOrder: sort_direction}

      @table.updateSettings
        cells: (row, col, prop) =>
          @format_cells(row, col, prop, @cell_metadata, @table)
        columnSorting: sorting
      @table.render()
