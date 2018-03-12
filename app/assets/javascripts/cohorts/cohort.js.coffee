#= require ./namespace

class App.Cohorts.Cohort
  constructor: (options) ->
    @wrapper_selector = options['wrapper_selector']
    @table_selector = options['table_selector']
    @batch_size = options['batch_size']
    @static_column_count = options['static_column_count']
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

    # Testing
    # @client_count = 15
    # @batch_size = 5

    @pages = Math.round(@client_count/@batch_size)

    @current_page = 0
    @raw_data = []

    @initialize_handsontable()
    @load_pages()
    
    @resizeable_fonts()
    # @load_pages()
    # @enable_highlight()
    # @enable_editing()

    # @refresh_rate = 10000
    # setInterval @check_for_new_data, @refresh_rate

  initialize_handsontable: () =>
    direction = true
    if @sort_direction == 'desc'
      direction = false
    @table = new Handsontable $(@table_selector)[0], 
      rowHeaders: true
      colHeaders: @column_headers
      correctFormat: true
      dateFormat: 'll'
      columns: @column_options
      fixedColumnsLeft: @static_column_count
      manualColumnResize: @column_widths
      columnSorting: 
          column: 1
          sortOrder: direction
      sortIndicator: true
      afterChange: @save_column

  load_pages: () =>
    $(@loading_selector).removeClass('hidden')
    @load_page().then(() =>
      # When we're all done fetching...
      $(@loading_selector).addClass('hidden')
      @format_data_for_table()
      # add the data to the table
      @table.loadData(@table_data)
      @table.updateSettings
        cells: (row, col, prop) =>
          @format_cells(row, col, prop, @cell_metadata, @table)
      # direction = true
      # if @sort_direction == 'desc'
      #   direction = false
      # @table.updateSettings
      #   columnSorting: 
      #     column: 1
      #     sortOrder: direction
      # @set_rank_order()
    )

  format_cells: (row, col, prop, metadata, table) ->
    cellProperties ={}
    # console.log row, col, metadata[row][col].cohort_client_id
    # table.setCellMeta(row, col, 'cohort_client_id', metadata[row][col].cohort_client_id)
    if metadata[row][col]?.editable == false
      cellProperties.readOnly = 'true'
    return cellProperties


  format_data_for_table: () =>
    @table_data = $.map @raw_data, (row) =>
      client = $.map @column_order, (column) =>
        if row[column]['value'] == null
          ''
        else
          row[column]['value']
      [client]
    @cell_metadata  = $.map @raw_data, (row) =>
      client = $.map @column_order, (column) =>
        m = row[column]
        m['column'] = column
        m
      [client]
    
  load_page: () =>
    @current_page += 1
    url =  "#{@client_path}.json?page=#{@current_page}&per=#{@batch_size}&content=true"
    if @include_inactive
      url += "&inactive=true"
    if @current_page > @pages + 1 
      return $.Deferred().resolve().promise()
    # Gather all the data first and then display it
    $.get({url: url}).done(@save_batch).then(@load_page)

  save_batch: (data, status) =>
    $.merge @raw_data, data
    percent_complete = Math.round(@current_page/@pages*100)
    $(@loading_selector).find('.percent-loaded').text("#{percent_complete}%")

  reinitialize_js: () ->
    $('.select2').select2();
    $('[data-toggle="tooltip"]').tooltip();

  resizeable_fonts: () =>
    $(@wrapper_selector).on 'click', @size_toggle_class, (e) =>
      clicked =  e.target
      size = $(clicked).data('size')
      $(@table_selector).removeClass('sm lg xl').addClass(size)
      $(clicked).siblings().removeClass('btn-primary').addClass('btn-secondary')
      $(clicked).removeClass('btn-secondary').addClass('btn-primary')
      @datatable.draw()
    
  set_rank_order: () =>
    ids = $(@datatable.rows().nodes()).filter(@client_row_class).map ()->
      $(this).data('cohort-client-id');
    $('#rank_order').val(ids.get().join(','));
    $('.jReRank').removeClass('disabled');

  save_column: (change, source) =>
    return if source == 'loadData'
    [row, column, original, current] = change[0]

    # translate the logical index (based on current sort order) to
    # the physical index (the row it was originally)
    physical_index = @table.sortIndex[row][0]
    meta = @raw_data[physical_index].meta
    column = @cell_metadata[row][column]
    field_name = "cohort_client[#{column.column}]"
    cohort_client_id = meta.cohort_client_id
    console.log row, column, meta, cohort_client_id
    $form = $(@cohort_client_form_selector)
    proxy_field = $form.find('.proxy_field')
    $(proxy_field).attr('name', field_name).attr('value', current)
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

      alert = "<div class='alert alert-#{alert_class}' style='position: fixed; top: 0;'>#{alert_text}</div>"
      $('.utility .alert').remove()
      $('.utility').append(alert)
      $('.utility .alert').delay(2000).fadeOut(250)

  check_for_new_data: =>    
    $.get @check_url, (data) =>
      if data != @updated_ats
        @update_outdated(data)

  update_outdated: (current) =>
    for cohort_client_id, updated_at of @updated_ats
      current_timestamp = current[cohort_client_id]
      if current_timestamp != updated_at
        selector = "#{@client_row_class}[data-cohort-client-id='#{cohort_client_id}']"
        # $row = $(selector)
        $rows = @datatable.rows(selector).nodes().to$()
        $rows.find(@input_selector).attr('disabled', 'disabled')
        @updated_ats[cohort_client_id] = current_timestamp
        $rows.find('td:first').html('<div class="icon-warning"></div><strong>Data has changed, please refresh.</strong>')
        $rows.addClass('warning')
        @datatable.draw()
