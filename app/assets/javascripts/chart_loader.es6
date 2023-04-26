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

  loadChartData(event) {
    event.preventDefault();
    let url = this.changerTarget.href;
    if (event.target) url = event.target.href;

    fetch(url)
      .then(response => response.json())
      .then(json => {
        // Deep copy initial config
        // Note: because we don't have full ES6/node support
        // we're bringing in rfdc in a weird way
        const clone = rfdc()
        let config = clone(this.initial_config);
        config.data = json.data;
        // data.labels.format is a function we can't send via json
        // so we need to grab it out of the initial config if it exists
        if (this.initial_config.data && this.initial_config.data.labels && this.initial_config.data.labels.format) config.data.labels.format = this.initial_config.data.labels.format
        if (this.initial_config.tooltip && this.initial_config.tooltip.format && this.initial_config.tooltip.format.value && this.initial_config.tooltip.format.value.format) config.tooltip.format.value.format = this.initial_config.tooltip.format.value.format

        let chart = this.chart();
        // completely remove the previous chart
        chart.destroy();
        // regenerate
        chart = bb.generate(config);

        // Update the header
        if (event.target) this.chartHeaderTarget.textContent = event.target.text;

        // Update the menu
        this.changerTargets.forEach(el => el.classList.remove('active'))
        let active_menu_item = this.changerTargets.find(el => el.dataset['menu-item'] == json.chart);
        active_menu_item.classList.add('active');
      })
  }
})
