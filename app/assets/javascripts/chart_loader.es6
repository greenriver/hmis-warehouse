window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

// Provides a means of reloading a fragment when an input changes
App.StimulusApp.register('chart-loader', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'changer']
  }

  // initialize() {
  //   console.log('chart-loader initializing')
  // }

  connect() {
    this.element['chartLoader'] = this // allow access to this controller from other controllers
    console.log(this.loadChartData(new Event('click')))
    // console.log(this.changerTarget)
    // this.watchForSelect2Opens()
  }

  chart() {
    return Function("return " + this.element.dataset.chart)()
  }

  loadChartData(event) {
    event.preventDefault();
    let url = this.changerTarget.href;
    if (event.target) {
      url = event.target.href;
    }

    fetch(url)
      .then(response => response.json())
      .then(json => {
        // console.log(json)
        this.chart().unload()
        this.chart().load(json);
        this.chart().groups(json.groups);
      })
  }
})
