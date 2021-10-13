/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
//= require ./namespace

window.App.WarehouseReports.HomelessSummaryReport.HorizontalBar = class HorizontalBar {
  constructor(chart_selector, options) {
    this._build_chart = this._build_chart.bind(this);
    this._colors = this._colors.bind(this);
    this._follow_link = this._follow_link.bind(this);
    this._observe = this._observe.bind(this);
    this._selector_exists = this._selector_exists.bind(this);
    this._selector_unprocessed = this._selector_unprocessed.bind(this);
    this.chart_selector = chart_selector;
    window.Chart.defaults.global.defaultFontSize = 10;
    this.truncate_labels = (options != null && options.truncate_labels != null) ? options.truncate_labels : 0;
    this.color_map = {};
    this.next_color = 0;
    if ((options != null ? options.remote : undefined) === true) {
      this._observe();
    } else {
      this._build_chart();
    }
  }

  _build_chart() {
    if ($(this.chart_selector).length > 0) {
      const self = this
      this.options = $(this.chart_selector).data('chart').options;
      this.categories = $(this.chart_selector).data('chart').categories;
      if (this.truncate_labels > 0) {
        // this.categories = this.categories.map(c => c.substring(0, this.truncate_labels))
        this.categories = this.categories.map(c => {
          separator = ' '
          if (c.length <= this.truncate_labels) return c;
          return c.substr(0, c.lastIndexOf(' ', this.truncate_labels)) + '...';
        })
      }
      this.link_params = $(this.chart_selector).data('chart').params;
      const { legendBindTo } = $(this.chart_selector).data('chart');

      this.padding = this.options.padding || {};
      this.height = this.options.height || 400;
      this.max_value = this.options.max || 100;
      // Deep clone array to prevent future issues with additional mutations
      const columns = $(this.chart_selector).data('chart').columns;
      const _columns = JSON.parse(JSON.stringify(columns));
      const setNames = [];
      const columnTotals = _columns.map((col) => {
        setNames.push(col[0]);
        col.shift();
        return col.reduce((a, b) => a + b, 0);
      });
      let data = {
        columns: columns,
        type: 'bar',
        color: this._colors,
        labels: {
          format: (v, id, i, j) => {
            if (this.options.showPercentageWithValue) {
              let percentage = 0
              let setIndex = setNames.indexOf(id)
              if (columnTotals[setIndex] > v) {
                percentage = (v/columnTotals[setIndex])*100
              }
              return `${d3.format(",")(v)} (${percentage.toFixed(1)}%)`;
            }
            return d3.format(",")(v);
          }
        },
        onclick: this._follow_link,
      };
      const config = {
        data,
        legend: {
          show: false,
        },
        bindto: this.chart_selector,
        size: {
          height: this.height,
        },
        axis: {
          rotated: true,
          y: {
            max: this.max_value,
            outer: false,
            tick: {
              rotate: -35,
              autorotate: true,
            },
          },
          x: {
            height: 100,
            type: 'category',
            categories: this.categories,
            outer: false,
            tick: {
              rotate: -35,
              autorotate: true,
              fit: true,
              culling: false,
            },
          },
        },
        grid: {
          y: {
            show: true,
          },
        },
        bar: {
          width: 15,
        },
        padding: {
          left: this.padding.left || 150,
          top: 0,
          bottom: 15,
        },
        tooltip: {
          contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
            return this._toolip(d, defaultTitleFormat, defaultValueFormat, color);
          }
        },
      };
      if (legendBindTo) {
        config.legend = {
          contents: {
            bindto: legendBindTo,
            template: (title, color) => {
              const swatch = `<svg class="chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
              return `<div class="chart-legend-item-prs1">${swatch}<div class="chart-legend-item-label-prs1">${title}</div></div>`;
            },
          },
        };
      }
      return (this.chart = window.bb.generate(config));
    } else {
      return console.log(`${this.chart_selector} not found on page`);
    }
  }

  _colors(c, d) {
    let color;
    let key = d;
    if (key.x != null) {
      key = key.x;
    }
    const colors = window.Chart.defaults.colors
    if (['All'].includes(key)) {
      color = '#288BEE';
    } else {
      color = this.color_map[key];
      if (color == null) {
        color = colors[this.next_color++];
        this.color_map[key] = color;
        this.next_color = this.next_color % colors.length;
      }
    }
    return color;
  }

  _follow_link(d) {
    if (this.options.follow_link !== true) {
      return;
    }

    const bucket_title = this.chart.categories()[d.index];
    const bucket = this.options.sub_keys[bucket_title];
    const report = 'report';
    if (__guard__(this.chart.data()[1], (x) => x.id) === d.id) {
      this.link_params.filters.start_date = this.options.date_ranges.comparison.start_date;
      this.link_params.filters.start = this.options.date_ranges.comparison.start_date;
      this.link_params.filters.end_date = this.options.date_ranges.comparison.end_date;
      this.link_params.filters.end = this.options.date_ranges.comparison.end_date;
    } else {
      this.link_params.filters.start_date = this.options.date_ranges.report.start_date;
      this.link_params.filters.start = this.options.date_ranges.report.start_date;
      this.link_params.filters.end_date = this.options.date_ranges.report.end_date;
      this.link_params.filters.end = this.options.date_ranges.report.end_date;
    }
    // If we clicked on a point, send us to the list of associated clients
    this.link_params.filters.report = report;
    if (bucket != null) {
      this.link_params.filters.sub_key = bucket;
    } else {
      this.link_params.filters.sub_key = '';
    }
    // console.log(@link_params, bucket)

    const url = '/' + this.options.link_base + '?' + $.param(this.link_params);
    // console.log(url)
    return window.open(url);
  }

  _toolip(d, defaultTitleFormat, defaultValueFormat, color) {
    // Somewhat reverse engineered from here:
    // https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110
    // console.log(d, defaultValueFormat(d[0].value), @data)
    const tooltip_title = defaultTitleFormat(d[0].x);
    let support = $(this.chart_selector).data('chart').support
    let html = "<table class='bb-tooltip'>";
    html += "<thead>";
    html += `<tr><th></th><th>${support.unit[d[0].index]}</th><th>Clients</th></tr>`;
    html += "</thead>";
    html += "<tbody>";
    $(d).each(i => {
      const row = d[i];

      if (row != null) {
        const bg_color = color(row.x);
        const box = `<td class='name'><svg><rect style='fill:${bg_color}' width='10' height='10'></rect></svg>${row.name}</td>`;
        const value = `<td>${row.value}</td>`;
        let details = `<td class='text-left'>${support.counts[tooltip_title]}</td>`;
        html += box;
        html += value;
        html += details;
        return html += "</tr>";
      }
    });

    html += "</tbody>";
    html += '</table>';
    return html;
  }

  _observe() {
    this.processed = [];
    const MutationObserver =
      window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;
    if (MutationObserver) {
      return new MutationObserver((mutations) => {
        return (() => {
          const result = [];
          for (let mutation of Array.from(mutations)) {
            if (
              $(mutation.target).data('complete') === 'true' &&
              this._selector_exists() &&
              this._selector_unprocessed()
            ) {
              // console.log($(@chart_selector).data(), @chart_selector)
              this._build_chart();
              result.push(this.processed.push(this.chart_selector));
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      }).observe(document.body, {
        childList: false,
        subtree: true,
        attributes: true,
        attributeFilter: ['complete'],
      });
    }
  }

  _selector_exists() {
    return $(this.chart_selector).length > 0;
  }

  _selector_unprocessed() {
    return !Array.from(this.processed).includes(this.chart_selector);
  }
};

function __guard__(value, transform) {
  return typeof value !== 'undefined' && value !== null ? transform(value) : undefined;
}
