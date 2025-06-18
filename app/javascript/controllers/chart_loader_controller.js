import { Controller } from "@hotwired/stimulus"
import bb, { bar, pie, donut } from "billboard.js";
import rfdc from 'rfdc'

export default class extends Controller {
  static get targets() {
    return ['element', 'changer', 'header', 'chart', 'table', 'wrapper', 'loader'];
  }

  connect() {
    this.element['chartLoader'] = this;
    this.initial_config = this.chart().config();
    if ($(this.changerTarget).data('chartData')) {
      this.loadChartDataSync();
    } else {
      this.loadChartData(new Event('click'));
    }
  }

  chart() {
    return Function('return ' + this.element.dataset.chart)();
  }

  chartTypes = {
    bar,
    pie,
    donut,
  }

  updateChart(data) {
    const clone = rfdc();
    let config = clone(this.initial_config);
    if (data.config) {
      config = {
        ...config,
        ...data.config,
      };
    }

    if (typeof config.data.type === 'string' && this.chartTypes[config.data.type]) {
      config.data.type = this.chartTypes[config.data.type]();
    }

    config.data = data.data;
    if (this.initial_config.data && this.initial_config.data.labels && this.initial_config.data.labels.format) config.data.labels.format = this.initial_config.data.labels.format;
    if (this.initial_config.tooltip && this.initial_config.tooltip.format && this.initial_config.tooltip.format.value && this.initial_config.tooltip.format.value.format) config.tooltip.format.value.format = this.initial_config.tooltip.format.value.format;

    let chart = this.chart();
    chart.destroy();
    this.showChartAndTable();
    chart = bb.generate(config);
  }

  updateTable(data, target) {
    let link_base = target.dataset['tableLink'];
    let table = this.createTable(data.table, link_base, data.link_params);
    let table_name = target.dataset['tableName'];
    if (table_name) {
      let table_header_html = document.createElement('h3');
      let table_header_text = document.createTextNode(table_name);
      table_header_html.appendChild(table_header_text);
      table.prepend(table_header_html);
    }
    if (this.tableTarget) this.tableTarget.innerHTML = table.outerHTML;
  }

  createTable(data, link_base, link_params) {
    let container = document.createElement('div');
    container.classList.add('overflow-x-scroll');
    let table = document.createElement('table');
    table.classList.add('table', 'table-striped');
    let tableBody = document.createElement('tbody');
    let row, cell, link, url;
    data.forEach(function (data_row, i) {
      row = document.createElement('tr');
      data_row.forEach(function (data_cell, j) {
        if (i > 0 && j > 0 && link_base) {
          url = new URL(link_base);
          url.searchParams.append(...link_params.columns[j]);
          url.searchParams.append(...link_params.rows[i]);
          cell = document.createElement('td');
          link = document.createElement('a');
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
    container.appendChild(table);
    return container;
  }

  enableLoader() {
    let loader = document.createElement('div');
    loader.classList.add('rollup-container', 'c-card', 'c-card--flush', 'c-card--block', 'mt-4');
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
    if (event.target) event.preventDefault();
    this.enableLoader();
    this.hideChartAndTable();
    let target = this.activeTarget(event);
    let url = target.href;
    fetch(url)
      .then(response => response.json())
      .then(json => {
        this.updateChart(json);
        if (target) this.headerTarget.textContent = target.text;
        this.changerTargets.forEach(el => el.classList.remove('active'));
        let active_menu_item = this.changerTargets.find(el => el.dataset['menuItem'] == json.chart);
        if (active_menu_item) active_menu_item.classList.add('active');
        this.updateTable(json, target);
        this.disableLoader();
      });
  }

  loadChartDataSync() {
    const target = this.changerTarget;
    const chartData = $(target).data('chartData');
    this.updateChart(chartData);
    this.updateTable(chartData, target);
  }

  activeTarget(event) {
    if (event.target) return event.target;
    if (event.jquery) return event[0];

    return this.changerTarget;
  }
}
