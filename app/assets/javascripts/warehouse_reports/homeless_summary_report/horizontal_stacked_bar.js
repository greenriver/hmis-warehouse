//= require ./namespace

window.App.WarehouseReports.HomelessSummaryReport.HorizontalStackedBar = class HorizontalBar {
  constructor(chart_selector, options) {
    this._build_chart = this._build_chart.bind(this);
    this._colors = this._colors.bind(this);
    this._observe = this._observe.bind(this);
    this._selector_exists = this._selector_exists.bind(this);
    this._selector_unprocessed = this._selector_unprocessed.bind(this);
    this.chart_selector = chart_selector;
    window.Chart.defaults.global.defaultFontSize = 10;
    this.truncate_labels = (options != null && options.truncate_labels != null) ? options.truncate_labels : 0;
    this.color_map = {};
    this.next_color = 0;
    this.legend_holder = options.legend_holder;
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

      this.padding = this.options.padding || {};
      this.height = this.options.height || 400;
      this.max_value = this.options.max || 100;
      // Deep clone array to prevent future issues with additional mutations
      const columns = $(this.chart_selector).data('chart').one_columns;
      const _columns = JSON.parse(JSON.stringify(columns));
      this.groups = $(this.chart_selector).data('chart').groups;
      const setNames = [];
      const columnTotals = _columns.map((col) => {
        setNames.push(col[0]);
        col.shift();
        return col.reduce((a, b) => a + b, 0);
      });
      let data = {
        x: 'x',
        columns: columns,
        groups: this.groups,
        type: 'bar',
        stack: {
          normalize: true
        },
      };
      const config = {
        data,
        legend: {
          show: (this.legend_holder != null) ? false : true,
        },
        bindto: this.chart_selector,
        size: {
          height: this.height,
        },
        axis: {
          width: 100,
          rotated: true,
          y: {
            max: this.max_value,
            outer: false,
            tick: {
              rotate: -35,
              autorotate: true,
              format: function (x) { return x + "%"; }
            },
          },
          x: {
            type: 'category',
            outer: false,
            tick: {
              rotate: -35,
              autorotate: true,
              fit: true,
              culling: false,
              width: 225,
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
          padding: 5,
        },
        padding: {
          left: this.padding.left || 250,
          top: 0,
          bottom: 40,
        },
        tooltip: {
          contents: (d, defaultTitleFormat, defaultValueFormat, color) => {
            return this._tooltip(d, defaultTitleFormat, defaultValueFormat, color);
          }
        },
      };
      if(this.legend_holder != null) {
        config.legend = {
          contents: {
            bindto: this.legend_holder,
            template: (title, color) => {
              const swatch = `<svg class="chart-legend-item-swatch-prs1" viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg"><rect width="10" height="10" fill="${color}"/></svg>`;
              return `<div class="chart-legend-item-prs1 align-items-center">${swatch}<div class="chart-legend-item-label-prs1">${title}</div></div>`;
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
    let key = this.categories.indexOf(d.id);
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

  _tooltip(d, defaultTitleFormat, defaultValueFormat, color) {
    // Somewhat reverse engineered from here:
    // https://github.com/naver/billboard.js/blob/aa91babc6d3173e58e56eef33aad7c7c051b747f/src/internals/tooltip.js#L110

    const tooltip_title = defaultTitleFormat(d[0].x);
    let support = $(this.chart_selector).data('chart').support
    // console.log(d, defaultValueFormat(d[0].value), support, tooltip_title)
    let html = "<table class='bb-tooltip' style='opacity: 1;'>";
    html += "<thead>";
    html += `<tr><th colspan='2'>${tooltip_title}</th><th>Destination Details</th></tr>`;
    html += "</thead>";
    html += "<tbody>";
    $(d).each(i => {
      const row = d[i];

      if (row != null) {
        const bg_color = color(row.id);
        const box = `<td class='name' style='width: 110px;'><svg><rect style='fill:${bg_color}' width='10' height='10'></rect></svg>${row.name.split(/[ ,]/)[0]}</td>`;
        const value = `<td style='width: 10%; white-space: nowrap;'>${row.value} (${parseFloat((row.ratio * 100.0).toFixed(1))}%)</td>`;
        const detailRows = support.all_detail_counts[tooltip_title][row.name].map(this.shortenDestinationDetail)
        const details = `<td class='text-left' style='white-space: nowrap;'>${detailRows.join('<br />')}</td>`;
        html += box;
        html += value;
        html += details;
        return html += "</tr>";
      }
    });

    html += "</tbody>";
    html += '</table>';
    $(".bb-tooltip-container").css("z-index", 1000);
    return html;
  }

  shortenDestinationDetail(str) {
    const lastIndex = str.lastIndexOf(':');
    let destinationDetail = str.slice(0, lastIndex);
    const count = str.slice(lastIndex + 1);
    // For long destination details, shorten them by dropping parenthesized text
    // 'Rental by client, with HCV voucher (tenant or project based)'  ==> 'Rental by client, with HCV voucher'
    if (destinationDetail.length > 30) {
      destinationDetail = destinationDetail.replace(/\([^()]*\)/g, '').trim();
    }
    // Special case to shorten especially long destination detail
    if (destinationDetail.length > 30 && destinationDetail.startsWith("Emergency shelter,")) {
      destinationDetail = "Emergency shelter"
    }
    return `${destinationDetail}:${count}`;
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
