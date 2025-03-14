import { AllCommunityModule, ModuleRegistry } from 'ag-grid-community';

// Register all Community features
ModuleRegistry.registerModules([AllCommunityModule]);

// import { DateCellEditor } from './cohorts_editors_cohorts_date_cell_editor.js'
import { DateCellEditor } from './cohorts/editors/date_cell_editor.js';
import { DateCellRenderer } from './cohorts/viewers/date_cell_renderer.js';
import { CheckboxCellEditor } from './cohorts/editors/checkbox_cell_editor.js';
import { CheckboxCellRenderer } from './cohorts/viewers/checkbox_cell_renderer.js';
import { DropdownCellEditor } from './cohorts/editors/dropdown_cell_editor.js';
import { HtmlCellRenderer } from './cohorts/viewers/html_cell_renderer.js';

window.App.Cohorts = window.App.Cohorts || {}
window.App.Cohorts.Cohort = class Cohort {
  constructor(options) {
    this.initialize_grid = this.initialize_grid.bind(this);
    this.resize_columns = this.resize_columns.bind(this);
    this.set_grid_column_headers = this.set_grid_column_headers.bind(this);
    this.sort_checkboxes = this.sort_checkboxes.bind(this);
    this.sort_dates = this.sort_dates.bind(this);
    this.sort_everything_else = this.sort_everything_else.bind(this);
    this.enable_searching = this.enable_searching.bind(this);
    this.enable_bulk_delete = this.enable_bulk_delete.bind(this);
    this.load_pages = this.load_pages.bind(this);
    this.load_page = this.load_page.bind(this);
    this.save_batch = this.save_batch.bind(this);
    this.set_rank_order = this.set_rank_order.bind(this);
    this.after_edit = this.after_edit.bind(this);
    this.check_for_new_data = this.check_for_new_data.bind(this);
    this.reload_client = this.reload_client.bind(this);
    this.wrapper_selector = options['wrapper_selector'];
    this.table_selector = options['table_selector'];
    this.batch_size = options['batch_size'];
    // @static_column_count = options['static_column_count']
    this.client_count = options['client_count'];
    this.sort_direction = options['sort_direction'];
    this.column_order = options['column_order'];
    this.column_headers = options['column_headers'];
    this.column_options = options['column_options'];
    this.column_widths = options['column_widths'];
    this.size_toggle_class = options['size_toggle_class'];
    this.include_inactive = options['include_inactive'];
    this.client_path = options['client_path'];
    this.client_row_class = options['client_row_class'];
    this.loading_selector = options['loading_selector'];
    this.cohort_client_form_selector = options['cohort_client_form_selector'];
    this.cohort_value_hidden_selector = options['cohort_value_hidden_selector'];
    this.check_url = options['check_url'];
    this.input_selector = options['input_selector'];
    this.updated_ats = options['updated_ats'];
    this.search_selector = options['search_selector'];
    this.search_actions_selector = options['search_actions_selector'];
    this.population = options['population'];
    this.thresholds = options['thresholds'];

    // Testing
    // @client_count = 15
    // @batch_size = 5

    this.pages = Math.round(this.client_count / this.batch_size);

    this.current_page = 0;
    this.raw_data = [];

    this.initialize_grid();

    this.load_pages();
    this.resize_columns();
    this.enable_searching();
    this.enable_bulk_delete();
  }

  initialize_grid() {
    this.set_grid_column_headers();

    this.grid_options = {
      columnDefs: this.grid_column_headers,
      defaultColDef: {
        sortable: true,
        filter: true,
        resizable: true
      },
      // enableSorting: true,
      // enableFilter: true,
      singleClickEdit: true,
      rowSelection: {
        mode: 'multiRow',
        enableClickSelection: true,
        checkboxes: false,
        headerCheckbox: false,
      },
      getRowId: params => params.data.meta.cohort_client_id.toString(),
      onSortChanged: data => data.api.redrawRows(),
      onFilterChanged: data => data.api.redrawRows(),
      onCellEditingStarted: params => {
        this.editing_field_name = params.colDef.field;
        this.editing_cohort_client_id = params.data[params.colDef.field].cohort_client_id;
        return this.editing_initial_value = params.value;
      },
      onCellEditingStopped: params => {
        // console.log @editing_field_name, @editing_cohort_client_id, @editing_initial_value
        const {
          cohort_client_id
        } = params.data[params.colDef.field];
        // don't save anything if we had no change
        if ((this.editing_field_name === params.colDef.field) && (this.editing_cohort_client_id === cohort_client_id) && (this.editing_initial_value === params.value)) {
          return;
        }
        let old_value = 'unknown';
        if ((this.editing_field_name === params.colDef.field) && (this.editing_cohort_client_id === cohort_client_id)) {
          old_value = this.editing_initial_value;
        }
        return this.after_edit(params.colDef.field, cohort_client_id, old_value, params.value, params.rowIndex);
      },
      getRowStyle: params => {
        let color = {};
        for (var threshold of Array.from(this.thresholds)) {
          if (params.node.rowIndex === threshold.row) {
            color = { 'border-top': `4px solid ${threshold.color}` };
          }
        }
        return color;
      },
      components: {
        dateCellEditor: DateCellEditor,
        dateCellRenderer: DateCellRenderer,
        checkboxCellEditor: CheckboxCellEditor,
        checkboxCellRenderer: CheckboxCellRenderer,
        dropdownCellEditor: DropdownCellEditor,
        htmlCellRenderer: HtmlCellRenderer,
      }
    };

    this.table = agGrid.createGrid($(this.table_selector)[0], this.grid_options);
  }

  resize_columns() {
    return this.table.autoSizeAllColumns();
  }

  set_grid_column_headers() {
    const row_number = {
      headerName: 'Row',
      pinned: 'left',
      valueGetter(params) {
        return params.node.rowIndex + 1;
      },
      suppressHeaderMenuButton: true,
      filter: false,
      sortable: false,
      cellStyle: { color: 'rgba(0, 0, 0, 0.54)', 'background-color': '#f5f7f7' }
    };
    this.grid_column_headers = $.map(this.column_headers, (column, index) => {
      const header = {
        headerName: column.headerName,
        headerTooltip: column.headerTooltip,
        field: column.field,
        editable: column.editable,
        // tooltip: (params) ->
        //   params.data[params.colDef.field].comments
        valueGetter(params) {
          return params.data[params.column.colId].value;
        },
        valueSetter(params) {
          if (params.oldValue !== params.newValue) {
            return params.data[params.colDef.field].value = params.newValue;
          } else {
            return false;
          }
        }
      };
      // no sort or filter on delete buttons
      if (column.field == 'delete') {
        header.filter = false
        header.sortable = false
      }
      // Set the default sort on the second column
      if (index === 1) {
        header.sort = this.sort_direction;
      }
      switch (column.renderer) {
        case 'checkbox':
          header.cellRenderer = 'checkboxCellRenderer';
          header.cellEditor = 'checkboxCellEditor';
          header.getQuickFilterText = '';
          header.comparator = this.sort_checkboxes;
          break;
        case 'date':
          header.cellRenderer = 'dateCellRenderer';
          header.cellEditor = 'dateCellEditor';
          header.comparator = this.sort_dates;
          header.getQuickFilterText = params => {
            return params.value;
          };
          break;
        case 'dropdown':
          header.cellEditor = 'agSelectCellEditor';
          header.cellEditorParams =
            { values: column.available_options, };
          header.cellRenderer = params => {
            return params.getValue();
          };
          break;
        case 'html':
          header.comparator = this.sort_everything_else;
          header.cellRenderer = 'htmlCellRenderer';
          break;
        default:
          header.comparator = this.sort_everything_else;
          header.cellRenderer = params => {
            return params.getValue();
          };
      }

      if (column.pinned != null) { header.pinned = column.pinned; }

      if (column.editable) {
        header.editable = column.editable;
      } else {
        header.editable = params => // console.log(params)
          params.data[params.column.colId].editable;
      }

      return header;
    });
    return this.grid_column_headers.unshift(row_number);
  }
  // This is to work around a bug in sorting checkboxes
  sort_checkboxes(a, b) {
    if (a === b) return 0;
    return a ? 1 : -1;
  }

  // work around our text based date format
  sort_dates(a, b) {
    const dateA = moment(a, 'MMM DD, YYYY').format('YYYYMMDD');
    const dateB = moment(b, 'MMM DD, YYYY').format('YYYYMMDD');
    if (!dateA || !dateB) return 0; // Prevent sorting errors
    return dateA.localeCompare(dateB);
  }

  sort_everything_else(a, b) {
    if (a == null) return -1;
    if (b == null) return 1;
    if (!isNaN(a) && !isNaN(b)) return Number(a) - Number(b);
    return a.toString().localeCompare(b.toString());
  }

  enable_searching() {
    const searchField = $(this.search_selector)[0];
    $(searchField).removeAttr('disabled');
    return $(searchField).on('keyup', e => {
      return this.table.setGridOption('quickFilterText', $(searchField).val());
    });
  }

  enable_bulk_delete() {
    const form = $(this.wrapper_selector).find('.jBulkDelete');
    const button = $(form).find('button');
    const cc_id_field = $(form).find('input.cohort_client_ids');
    return $(button).on('click', e => {
      e.preventDefault();
      const cohort_client_ids = $.map(this.table.getSelectedRows(), (column, index) => {
        return column.meta.cohort_client_id;
      });
      if (cohort_client_ids.length > 0) {
        cc_id_field.attr('value', cohort_client_ids);
      }
      return $(form).trigger('submit');
    });
  }



  load_pages() {
    $(this.loading_selector).removeClass('hidden');
    return this.load_page().then(() => {
      // When we're all done fetching...
      $(this.loading_selector).addClass('hidden');
      // console.log(this.raw_data, this.table);
      this.table.setGridOption('rowData', this.raw_data);
      this.set_rank_order();

      this.refresh_rate = 10000;
      return setInterval(this.check_for_new_data, this.refresh_rate);

    });
  }

  load_page() {
    this.current_page += 1;
    let url = `${this.client_path}.json?page=${this.current_page}&per=${this.batch_size}&content=true`;
    if (this.include_inactive) {
      url += "&inactive=true";
    }
    if (this.population != null) {
      url += `&population=${this.population}`;
    }

    if (this.current_page > (this.pages + 1)) {
      return $.Deferred().resolve().promise();
    }
    // Gather all the data first and then display it
    return $.get({ url }).then(this.save_batch).then(this.load_page);
  }

  save_batch(data, status) {
    $.merge(this.raw_data, data);
    const percent_complete = Math.round(((this.current_page - 1) / this.pages) * 100);
    return $(this.loading_selector).find('.percent-loaded').text(`${percent_complete}%`);
  }

  set_rank_order() {
    const ids = [];
    this.table.forEachNodeAfterFilterAndSort(data => {
      return ids.push(data.data.meta.cohort_client_id);
    });
    $('#rank_order').val(ids.join(','));
    return $('.jReRank').removeClass('disabled');
  }


  after_edit(column, cohort_client_id, old_value, new_value, rowIndex = null) {
    // console.log column, cohort_client_id, old_value, new_value

    const field_name = `cohort_client[${column}]`;
    const $form = $(this.cohort_client_form_selector);
    const proxy_field = $form.find('.proxy_field');
    $(proxy_field).attr('name', field_name).attr('value', new_value);
    const url = $form.attr('action').replace('cohort_client_id', cohort_client_id);
    const method = $form.attr("method");
    const data = $form.serialize();
    const options = {
      url: `${url}.js`,
      type: method,
      data,
      dataType: 'json'
    };

    return $.ajax(options).done(data => {
      const alert_class = data.alert;
      const alert_text = data.message;
      const {
        updated_at
      } = data;
      ({
        cohort_client_id
      } = data);

      // Make note of successful update
      this.updated_ats[cohort_client_id] = updated_at;

      if (rowIndex) {
        const $row = $(`.ag-row[row-index=${rowIndex}]`);
        $row.addClass('highlight-positive');
        setTimeout(() => $row.removeClass('highlight-positive')
          , 2000);
      }
      const alert = `<div class='alert alert-${alert_class}' style='position: fixed; top: 70px; z-index: 1500;'>${alert_text}</div>`;
      $('.utility .alert').remove();
      $('.utility').append(alert);
      return $('.utility .alert').delay(2000).fadeOut(250);
    });
  }

  check_for_new_data() {
    return $.get(this.check_url, data => {
      // console.log 'checking', @updated_ats
      let changed = false;
      $.each(data, (id, timestamp) => {
        if (timestamp !== this.updated_ats[id]) {
          changed = true;
          // console.log "didn't match", @updated_ats
          // console.log({client_id: id, server_timestamp: timestamp, client_timestamp: @updated_ats[id]})
          return this.reload_client(id);
        }
      });
      if (changed) {
        // console.log 'Setting new updated ats'
        return this.updated_ats = data;
      }
    });
  }

  reload_client(cohort_client_id) {
    const url = `${this.client_path}.json?page=1&per=10&content=true&inactive=true&skip_trackable=true&cohort_client_id=${cohort_client_id}`;
    // Force synchronous loads so we don't fire dozens of queries simultaneously
    return $.ajax({
      async: false,
      url,
      success: data => {
        const client = data[0];
        const rowNode = this.table.getRowNode(client.meta.cohort_client_id);
        return rowNode.setData(client);
      }
    });
  }
};
