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
    @search_selector = options['search_selector']

    # Testing
    # @client_count = 15
    # @batch_size = 5

    @pages = Math.round(@client_count/@batch_size)

    @current_page = 0
    @raw_data = []

    @initialize_handsontable()
    @enable_searching()
    @load_pages()
    @listen_for_page_resize()
    
    @refresh_rate = 10000
    setInterval @check_for_new_data, @refresh_rate

  initialize_handsontable: () =>
    @direction = true
    if @sort_direction == 'desc'
      @direction = false
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
          sortOrder: @direction
      sortIndicator: true
      afterChange: @save_column
      search: true
      comments: true


  enable_searching: () =>
    searchField = $(@search_selector)[0]
    Handsontable.dom.addEvent searchField, 'keyup', (e) =>
      search_string = $(e.target).val()
      queryResult = @table.search.query(search_string)
      @filter_rows('' + search_string)
      @table.render()

  filter_rows: (search) =>
    # console.log "searching for: #{search}"
    data = @table_data
    if search == ''
      @table.loadData(data)
      return
    limited_data = []
    limited_metadata = []
    for row in [0...data.length] by 1
      for col in [0...data.length] by 1
        if ('' + data[row][col]).toLowerCase().indexOf(search.toLowerCase()) > -1
          # console.log "Found in: #{data[row][col]}"
          limited_data.push(data[row])
          # limited_metadata.push(metadata_copy[row])
          break
    @table.loadData(limited_data);
    # TODO: notes/comments are not correctly limited by filtering

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
        columnSorting: 
          column: 1
          sortOrder: @direction
      # console.log @raw_data
      @set_rank_order()
      @table.render()
    )

  format_cells: (row, col, prop, metadata, table) ->
    cellProperties ={}

    meta = metadata[row][col]
    row_meta = @raw_data[row].meta

    classes = []

    # mark read-only cells as such
    if meta?.editable == false
      cellProperties.readOnly = 'true'

    if meta.comments != null
      cellProperties.comment = {value: meta.comments}

    if meta.renderer == 'checkbox' || meta.column == 'notes'
      classes.push('htCenter')
      classes.push('htMiddle')

    # mark inactive clients
    if row_meta.activity == 'homeless_inactive'
      classes.push(row_meta.activity)

    # mark ineligible clients
    if row_meta.ineligible == true
      classes.push('cohort_client_ineligible')

    cellProperties.className = classes.join(' ')
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
    $('[data-toggle="tooltip"]').tooltip();
  
  listen_for_page_resize: () =>
    $(window).resize () =>
      @table.render()

  set_rank_order: () =>
    ids = for i in [0...@table.countRows()] by 1
      physical_index = @table.sortIndex[i][0]
      meta = @raw_data[physical_index].meta
      cohort_client_id = meta.cohort_client_id
    $('#rank_order').val(ids.join(','));
    $('.jReRank').removeClass('disabled');

  save_column: (change, source) =>
    return if source == 'loadData'
    [row, col, original, current] = change[0]
    return if original == current
    # translate the logical index (based on current sort order) to
    # the physical index (the row it was originally)
    physical_index = @table.sortIndex[row][0]
    meta = @raw_data[physical_index].meta
    column = @cell_metadata[row][col]
    return unless column.editable
    @table.validateRows [row], (valid) =>
      if valid
        field_name = "cohort_client[#{column.column}]"
        cohort_client_id = meta.cohort_client_id
        # console.log row, column, meta, cohort_client_id
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
          physical_index = @table.sortIndex[row][0]
          @table_data[physical_index][col] = current
          # console.log "saved", row, col, original, current, physical_index

          alert = "<div class='alert alert-#{alert_class}' style='position: fixed; top: 0;'>#{alert_text}</div>"
          $('.utility .alert').remove()
          $('.utility').append(alert)
          $('.utility .alert').delay(2000).fadeOut(250)

  check_for_new_data: =>    
    $.get @check_url, (data) =>
      # console.log 'checking'
      $.each data, (id, timestamp) =>
        if timestamp != @updated_ats[id]
          # console.log(id, timestamp, @updated_ats[id])
          @reload_client(id)
      @updated_ats = data
          
  reload_client: (cohort_client_id) =>
    url =  "#{@client_path}.json?page=1&per=10&content=true&inactive=true&cohort_client_id=#{cohort_client_id}"
    $.get url, (data) =>
      client = data[0]
      $.each @cell_metadata, (i, row) =>
        $.each row, (j, col) =>
          if col.cohort_client_id == +cohort_client_id
            if col.value != client[col.column].value
              # console.log i,j, client[col.column].value, @table_data[i][1], @table_data[i][j]
              @cell_metadata[i][j].comments = client[col.column].comments
              @table_data[i][j] = client[col.column].value

      @table.updateSettings
        cells: (row, col, prop) =>
          @format_cells(row, col, prop, @cell_metadata, @table)
      @table.render()
