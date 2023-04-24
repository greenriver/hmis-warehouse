window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

// Provides a means of reloading a fragment when an input changes
App.StimulusApp.register('section-changer', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'changer']
  }

  // initialize() {
  //   console.log('section-changer initializing')
  // }

  connect() {
    this.element['sectionChanger'] = this // allow access to this controller from other controllers
    // console.log('connected')
    // console.log(this.changerTarget)
    // this.watchForSelect2Opens()
  }


  replaceSection(event) {
    event.preventDefault();

    console.log(this.changerTarget.href)
    // let $project_controller = $('[data-stimulus-select-target*="projects"]').closest('[data-controller*="stimulus-select"]')
    // console.log()
  }
})
