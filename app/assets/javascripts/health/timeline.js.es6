//= require ./namespace

const monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];


App.Health.EntryTimeline = class EntryTimeline {
  constructor(element, config, options={}) {
    this.element = element;
    this.options = options;
    this.render(config);
  }

  render(config) {
    this.chart = bb.generate(
      Object.assign(config, {
        bindto: this.element,
        size: {
          height: this.options.height || 100,
        },
        legend: {
          show: false
        },
        point: {
          r: (d) => (d.value ? 8 : 0),
          opacity: 1
        },
        axis: {
          y: {
            show: false,
            min: 0,
            max: 1
          },
          x: {
            type: 'timeseries',
            tick: {
              format: (x) => monthNames[x.getMonth()],
              fit: false,
              count: 5,
              show: false,
              outer: false,
              text: {
                position: {
                  x: 5,
                  y: 0
                }
              }
            }
          }
        }
      })
    );
  }
};
