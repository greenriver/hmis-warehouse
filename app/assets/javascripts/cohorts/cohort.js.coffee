#= require ./namespace

class App.Cohorts.Cohort
  constructor: (options) ->
    @wrapper_selector = options['wrapper_selector']
    @table_selector = options['table_selector']
    @batch_size = options['batch_size']
    @static_column_count = options['static_column_count']
    @client_count = options['client_count']
    @sort_direction = options['sort_direction']
    @size_toggle_class = options['size_toggle_class']
    @include_inactive = options['include_inactive']
    @client_path = options['client_path']
    @client_row_class = options['client_row_class']
    @loading_selector = options['loading_selector']
    @cohort_client_form_selector = options['cohort_client_form_selector']

    # Testing
    @client_count = 15
    @batch_size = 5

    @pages = Math.round(@client_count/@batch_size)

    @current_page = 0
    @row_data = ''

    @initialize_data_table()

    @resizeable_fonts()
    @load_pages()
    @enable_highlight()
    @enable_editing()

  initialize_data_table: () =>
    @datatable = $(@table_selector).DataTable
      # scrollY: '70vh',
      scrollY: false,
      scrollX: true,
      scrollCollapse: false,
      # fixedHeader: true,
      lengthMenu: [ 5, 10, 25, 50]
      paging: true,
      fixedColumns: {
       leftColumns: @static_column_count
      },
      order: [[1, @sort_direction]]
    @datatable.on 'draw', () =>
      @reinitialize_js()


  save_batch: (data) =>
    @row_data += data
    percent_complete = Math.round(@current_page/@pages*100)
    $(@loading_selector).find('.percent-loaded').text("#{percent_complete}% (#{@current_page} of #{@pages})")

  load_pages: () =>
    $(@loading_selector).removeClass('hidden')
    @load_page().then(() =>
      # When we're all done fetching...
      $(@loading_selector).addClass('hidden')
      @datatable.rows.add($(@row_data).filter('tr')).draw();

      @set_rank_order()
    )

  add_rows: (data) =>
    @datatable.rows.add($(data).filter('tr')).draw();
    percent_complete = Math.round(@current_page/@pages*100)
    $(@loading_selector).find('.percent-loaded').text("#{percent_complete}% (#{@current_page} of #{@pages})")

  load_page: () =>
    @current_page += 1
    url =  "#{@client_path}?page=#{@current_page}&per=#{@batch_size}"
    if @include_inactive
      url += "&inactive=true"
    if @current_page > @pages
      return $.Deferred().resolve().promise()
    # Gather all the data first and then display it
    # $.get({url: url, dataType: 'html'}).done(@save_batch).then(@load_page)
    
    # Or, add data to the table as soon as it's available
    $.get({url: url, dataType: 'html'}).done(@add_rows).then(@load_page)

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
    
  enable_highlight: () =>
    $('.cohorts').on 'click', '.jSelectRow', (e) =>
      cohort_client_id = $(e.target).closest('tr').data('cohort-client-id')
      row = @datatable.row("[data-cohort-client-id=#{cohort_client_id}]").node()
      $(row).siblings().removeClass('info')
      $(row).toggleClass('info')
      @datatable.draw()

  set_rank_order: () =>
    ids = $(@datatable.rows().nodes()).filter(@client_row_class).map ()->
      $(this).data('cohort-client-id');
    $('#rank_order').val(ids.get().join(','));
    $('.jReRank').removeClass('disabled');

  enable_editing: () =>
    $(@wrapper_selector).on 'change', 'input,select,textarea*', (e) =>
      $field = $(e.target)
      cohort_client_id = $field.closest('tr').data('cohort-client-id')
      field_name = $field.attr('name').replace("[#{cohort_client_id}]", '')
      $form = $(@cohort_client_form_selector)
      url = $form.attr('action').replace('cohort_client_id', cohort_client_id)
      $form.attr('action', url)
      proxy_field = $form.find('.proxy_field')
      $(proxy_field).attr('name', field_name).attr('value', $field.val())

      method = $form.attr("method");
      data = $form.serialize();
      options = {
        url : "#{url}.js",
        type: method,
        data: data,
        dataType: 'json' 
      }
      $.ajax(options).complete (jqXHR) ->
        response = JSON.parse(jqXHR.responseText)
        alert_class = response.alert
        alert_text = response.message
        alert = "<div class='alert alert-#{alert_class}' style='position: fixed; top: 0;'>#{alert_text}</div>"
        $('.utility .alert').remove()
        $('.utility').append(alert)
        $('.utility .alert').delay(2000).fadeOut(250)
      
      
        