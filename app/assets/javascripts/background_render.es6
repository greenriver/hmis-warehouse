App.StimulusApp.register('background-render', class extends Stimulus.Controller {
  static get values() {
    return {renderId: String, url: String, fetchParams: Object}
  }

  connect() {
    // console.log('Connected')
    // set a unique id for this render
    this.renderIdValue = this.uuid()

    // subscribe to the channel and watch for updates from action_cable
    this.subscription = App.cable.subscriptions.create({channel: "BackgroundRenderChannel", id: this.renderIdValue}, {
      connected: () => {
        this.fetch()
      },
      received: (data) => {
        if (data.cableReady) CableReady.perform(data.operations)
      }
    });

  }

  uuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  fetch() {
    // send an ajax request to kick off the render job
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    const body = this.fetchParamsValue
    body.render_id = this.renderIdValue

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(body)
    }).catch( () => {
      window.alert("Sorry, an error occurred while loading page content.  Please refresh the page and try again.")
    })
  }

  disconnect() {
    App.cable.subscriptions.remove(this.subscription)
  }



})
