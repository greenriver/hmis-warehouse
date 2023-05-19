window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

// Provides a means of reloading a fragment when an input changes
App.StimulusApp.register('chart-loader', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'changer', 'header', 'chart', 'table', 'wrapper', 'loader']
  }

  connect() {
    // allow access to this controller from other controllers
    this.element['chartLoader'] = this
    // trigger initial click to load data
    this.loadChartData(new Event('click'));
    this.initial_config = this.chart().config();
  }

  chart() {
    return Function('return ' + this.element.dataset.chart)()
  }

  updateChart(data) {
    // Deep copy initial config
    // Note: because we don't have full ES6/node support
    // we're bringing in rfdc in a weird way
    const clone = rfdc()
    let config = clone(this.initial_config);
    if (data.config) {
      config = {
        ...config,
        ...data.config,
      }
    }
    config.data = data.data;
    // data.labels.format is a function we can't send via json
    // so we need to grab it out of the initial config if it exists
    if (this.initial_config.data && this.initial_config.data.labels && this.initial_config.data.labels.format) config.data.labels.format = this.initial_config.data.labels.format
    if (this.initial_config.tooltip && this.initial_config.tooltip.format && this.initial_config.tooltip.format.value && this.initial_config.tooltip.format.value.format) config.tooltip.format.value.format = this.initial_config.tooltip.format.value.format

    let chart = this.chart();
    // completely remove the previous chart
    chart.destroy();
    this.showChartAndTable();
    // regenerate
    chart = bb.generate(config);
  }

  updateTable(data, event) {
    let link_base = this.activeTarget(event).dataset['table-link'];
    let table = this.createTable(data.table, link_base, data.link_params)
    let table_name = this.activeTarget(event).dataset['table-name'];
    if (table_name) {
      let table_header_html = document.createElement('h3');
      let table_header_text = document.createTextNode(table_name);
      table_header_html.appendChild(table_header_text);
      table.prepend(table_header_html);
    }
    if (this.tableTarget) this.tableTarget.innerHTML = table.outerHTML;
  }

  createTable(data, link_base, link_params) {
    let table = document.createElement('table');
    table.classList.add('table', 'table-striped')
    // TODO: break table header out
    let tableBody = document.createElement('tbody');
    let row, cell, link, url;
    data.forEach(function (data_row, i) {
      row = document.createElement('tr');

      data_row.forEach(function (data_cell, j) {
        if(i > 0 && j > 0 && link_base) {
          url = new URL(link_base);
          // TODO: this is specific to the system pathways report
          // and should be generalized
          //url.searchParams.append('demographic', data[0][j]);
          //url.searchParams.append('node', data[i][0]);
          url.searchParams.append(...link_params.columns[j]);
          url.searchParams.append(...link_params.rows[i]);
          cell = document.createElement('td');
          link = document.createElement('a')
          link.setAttribute('target', '_blank');
          link.appendChild(document.createTextNode(data_cell.toLocaleString('en-US')));
          link.href = url.href;
          cell.appendChild(link);
        } else {
          cell = document.createElement('th');
          cell.appendChild(document.createTextNode(data_cell.toLocaleString('en-US')));
        }
        row.appendChild(cell);
      });

      tableBody.appendChild(row);
    });
    table.appendChild(tableBody);
    return table;
  }

  enableLoader() {
    let loader = document.createElement('div');
    loader.classList.add('rollup-container', 'c-card', 'c-card--flush', 'c-card--block', 'mt-4')
    loader.dataset.chartLoaderTarget = 'loader';
    this.wrapperTarget.appendChild(loader);
  }

  disableLoader() {
    this.loaderTarget.remove();
  }

  hideChartAndTable() {
    this.chartTarget.classList.add('hide');
    this.tableTarget.classList.add('hide');
  }

  showChartAndTable() {
    this.chartTarget.classList.remove('hide');
    this.tableTarget.classList.remove('hide');
  }

  loadChartData(event) {
    event.preventDefault();
    this.enableLoader();
    this.hideChartAndTable();
    let url = this.activeTarget(event).href;
    fetch(url)
      .then(response => response.json())
      .then(json => {
        this.updateChart(json)
        // Update the header
        if (event.target) this.headerTarget.textContent = event.target.text;
        // Update the menu
        this.changerTargets.forEach(el => el.classList.remove('active'))
        let active_menu_item = this.changerTargets.find(el => el.dataset['menu-item'] == json.chart);
        if (active_menu_item) active_menu_item.classList.add('active');
        this.updateTable(json, event);
        this.disableLoader();
      })
  }

  activeTarget(event) {
    if(event.target) return event.target

    return this.changerTarget
  }
})
