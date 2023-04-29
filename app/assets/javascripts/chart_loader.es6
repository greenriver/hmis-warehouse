window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

// Provides a means of reloading a fragment when an input changes
App.StimulusApp.register('chart-loader', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'changer', 'chartHeader']
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
    // regenerate
    chart = bb.generate(config);
  }

  updateTable(data, event) {
    //console.log(data)
    let link_base = this.activeTarget(event).dataset['table-link'];
    let table = this.createTable(data.table, link_base, data.link_params)
    let table_target = document.getElementById(this.activeTarget(event).dataset['table-id'])
    let table_name = this.activeTarget(event).dataset['table-name'];
    if (table_name) {
      let table_header_html = document.createElement('h3');
      let table_header_text = document.createTextNode(table_name);
      table_header_html.appendChild(table_header_text);
      table.prepend(table_header_html);
    }
    if (table_target) table_target.innerHTML = table.outerHTML;
  }

  createTable(data, link_base, link_params) {
    console.log(data)
    let table = document.createElement('table');
    table.classList.add('table', 'table-striped')
    // TODO: break table header out
    let tableBody = document.createElement('tbody');
    let row, cell, link, url;
    // console.log('here', data, link_params)
    data.forEach(function (data_row, i) {
      // console.log(data_row)
      row = document.createElement('tr');

      data_row.forEach(function (data_cell, j) {
        // console.log('cell:', data_cell, data_row, i, j, link_params)
        if(i > 0 && j > 0 && link_base) {
          url = new URL(link_base);
          // TODO: this is specific to the system pathways report
          // and should be generalized
          //url.searchParams.append('demographic', data[0][j]);
          //url.searchParams.append('node', data[i][0]);
          url.searchParams.append(...link_params.columns[j]);
          url.searchParams.append(...link_params.rows[i]);
          // console.log(link_params.columns[j], link_params.rows[i])
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

  loadChartData(event) {
    event.preventDefault();
    let url = this.activeTarget(event).href;
    fetch(url)
      .then(response => response.json())
      .then(json => {

        'rollup-container', 'c-card', 'c-card--flush', 'c-card--block'
        this.updateChart(json)
        // Update the header
        if (event.target) this.chartHeaderTarget.textContent = event.target.text;
        // Update the menu
        this.changerTargets.forEach(el => el.classList.remove('active'))
        let active_menu_item = this.changerTargets.find(el => el.dataset['menu-item'] == json.chart);
        active_menu_item.classList.add('active');
        this.updateTable(json, event)
      })
  }

  activeTarget(event) {
    if(event.target) return event.target

    return this.changerTarget
  }
})
