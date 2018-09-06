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
    @enable_searching()

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
      rowSelection: 'multiple',
      getRowNodeId: (data) ->
        data.meta.cohort_client_id
      components:
          dateCellEditor: DateCellEditor,
          dateCellRenderer: DateCellRenderer,
          checkboxCellEditor: CheckboxCellEditor,
          checkboxCellRenderer: CheckboxCellRenderer,
          dropdownCellEditor: DropdownCellEditor,
    }
    @table = new agGrid.Grid($(@table_selector)[0], @grid_options)

  resize_columns: =>
    @grid_options.columnApi.autoSizeColumns(@grid_options.columnApi.getAllColumns())

  set_grid_column_headers: =>
    @grid_column_headers = $.map @column_headers, (column, index) =>
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
          # console.log 'changed', params.oldValue, 'to', params.newValue, cohort_client_id
          @after_edit(params.colDef.field, cohort_client_id, params.oldValue, params.newValue)
      }
      # Set the default sort on the second column
      if index == 1
        header.sort = 'desc'

      switch column.renderer
        when 'checkbox'
          header.cellRenderer = 'checkboxCellRenderer'
          header.cellEditor = 'checkboxCellEditor'
          header.getQuickFilterText = ''
          header.comparator = @sort_checkboxes
        when 'date'
          header.cellRenderer = 'dateCellRenderer'
          header.cellEditor = 'dateCellEditor'
          header.getQuickFilterText = (params) =>
            params.value
        when 'dropdown'
          header.cellEditor = 'agSelectCellEditor'
          header.cellEditorParams =
            values: column.available_options,
          header.cellRenderer = (params) =>
            params.getValue()
        else
          header.cellRenderer = (params) =>
            params.getValue()

      header.pinned = column.pinned if column.pinned?

      if column.editable
        header.editable = column.editable
      else
        header.editable = (params) ->
          # console.log(params)
          params.data[params.column.colId].editable

      header

  # This is to work around a bug in sorting checkboxes
  sort_checkboxes: (a, b) =>
    if a == b
      return 0
    if a then 1 else -1

  enable_searching: () =>
    searchField = $(@search_selector)[0]
    $(searchField).removeAttr('disabled')
    $(searchField).on 'keyup', (e) =>
      @grid_options.api.setQuickFilter($(searchField).val());

  load_pages: () =>
    $(@loading_selector).removeClass('hidden')
    @load_page().then(() =>
      # When we're all done fetching...
      $(@loading_selector).addClass('hidden')
      # console.log @raw_data
      @grid_options.api.setRowData(@raw_data)
      @set_rank_order()

      @refresh_rate = 10000
      setInterval @check_for_new_data, @refresh_rate



    )

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

  set_rank_order: () =>
    ids = []
    @grid_options.api.forEachNodeAfterFilterAndSort((data) =>
      ids.push(data.data.meta.cohort_client_id)
    )
    $('#rank_order').val(ids.join(','));
    $('.jReRank').removeClass('disabled');


  after_edit: (column, cohort_client_id, old_value, new_value) =>
    # console.log column, cohort_client_id, old_value, new_value

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
      rowNode = @grid_options.api.getRowNode(client.meta.cohort_client_id)
      rowNode.setData(client)
