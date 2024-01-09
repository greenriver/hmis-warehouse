//= require ./namespace

window.App.WarehouseReports.PerformanceDashboards.Pie = class Pie {
  constructor(chart_selector, options) {
    this._build_chart = this._build_chart.bind(this);
    this._colors = this._colors.bind(this);
    this._observe = this._observe.bind(this);
    this._selector_exists = this._selector_exists.bind(this);
    this._selector_unprocessed = this._selector_unprocessed.bind(this);
    this.chart_selector = chart_selector;
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
      this.options = $(this.chart_selector).data('chart').options;
      this.categories = $(this.chart_selector).data('chart').categories;
      this.link_params = $(this.chart_selector).data('chart').params;

      const legendPosition = this.options.legendPosition || 'bottom'
      this.padding = this.options.padding || {};
      this.height = this.options.height || 400;
      const data = {
        columns: $(this.chart_selector).data('chart').columns,
        type: 'pie',
        color: this._colors,
        onclick: this._follow_link,
      };
      const config = {
        data,
        bindto: this.chart_selector,
        size: {
          height: this.height,
        },
        legend: {
          position: legendPosition,
        },
        padding: {
          left: this.padding.left || 150,
          top: 0,
          bottom: 20,
        },
      };
      return (this.chart = window.bb.generate(config));
    } else {
      return console.log(`${this.chart_selector} not found on page`);
    }
  }

  _colors(c, d) {
    let color;
    let key = d;
    if (key.id != null) {
      key = key.id;
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
      this.link_params.filters.end_date = this.options.date_ranges.comparison.end_date;
    } else {
      this.link_params.filters.start_date = this.options.date_ranges.report.start_date;
      this.link_params.filters.end_date = this.options.date_ranges.report.end_date;
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
