window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('stimulus-select', class extends Stimulus.Controller {
  static get targets() {
    return [
      'stimulusSelectElement'
    ]
  }

  sayHello() {
    console.log('sayHello fired')
  }

  initialize() {
    console.log('initializing')
    this.fetch_remote_data()
  }

  fetch_remote_data() {
    this.stimulusSelectElementTargets.forEach((el) => {
      $select = $(el).filter('[data-collection-path]')
      if ($select.length) {
        // remote load
        console.log($select)
        // FIXME
        [url, data] = $select.data('collection-path').split('?')
        original_placeholder = $select.attr('placeholder') || 'Please choose'
        loading_placeholder = 'Loading...'
        $select.attr('placeholder', loading_placeholder)
        // $.post(url, data), (data) =>
        //   $select.append(data)
        //   $select.attr('placeholder', original_placeholder)
      }
    })
  }
})
