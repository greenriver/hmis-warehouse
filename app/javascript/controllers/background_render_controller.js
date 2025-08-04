import { Controller } from "@hotwired/stimulus"
import CableReady from 'cable_ready'

export default class extends Controller {
  static get values() {
    return { renderId: String, url: String, fetchParams: Object };
  }

  connect() {
    this.renderIdValue = this.uuid();

    this.subscription = App.cable.subscriptions.create({ channel: 'BackgroundRenderChannel', id: this.renderIdValue }, {
      connected: () => {
        this.fetch();
      },
      received: (data) => {
        if (data.cableReady) CableReady.perform(data.operations);
      }
    });
  }

  uuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  fetch() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    const body = this.fetchParamsValue;
    body.render_id = this.renderIdValue;

    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    }).catch(() => {
      window.alert('Sorry, an error occurred while loading page content.  Please refresh the page and try again.');
    });
  }

  disconnect() {
    App.cable.subscriptions.remove(this.subscription);
  }
}
