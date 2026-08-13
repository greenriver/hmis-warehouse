import { Controller } from '@hotwired/stimulus';

// Polls a URL and replaces this element with the HTML the URL returns.
//
// The replacement markup carries its own data-poll-replace-* attributes, so the
// server decides whether polling continues: render the element with
// data-poll-replace-active-value="true" to keep polling, "false" to stop. Only
// one request is in flight at a time (the next one is scheduled after the
// previous response), so slow responses cannot compound.
//
// A 204 response means "there is nothing left to poll for" and reloads the page,
// which is how a background process that changed the rest of the page surfaces.
//
// Usage:
//   %div{ data: { controller: 'poll-replace',
//                 poll_replace_url_value: some_status_path(record),
//                 poll_replace_active_value: running.to_s,
//                 poll_replace_interval_value: 30000 } }
export default class extends Controller {
  static values = {
    url: String,
    active: Boolean,
    interval: { type: Number, default: 30000 },
  };

  connect() {
    this.scheduleNextPoll();
  }

  disconnect() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
  }

  scheduleNextPoll() {
    if (!this.activeValue || !this.urlValue) return;

    this.timer = setTimeout(() => this.poll(), this.intervalValue);
  }

  poll() {
    // request.xhr? on the Rails side looks for this header, which fetch does not
    // send on its own.
    fetch(this.urlValue, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then((response) => {
        if (response.status === 204) {
          window.location.reload();
          return null;
        }
        // Stop polling on an error rather than hammering the endpoint.
        if (!response.ok) return null;

        return response.text();
      })
      .then((html) => {
        // Replacing the element disconnects this controller; the incoming markup
        // connects a fresh one that decides whether to keep polling.
        if (html !== null) this.element.outerHTML = html;
      })
      .catch(() => this.scheduleNextPoll());
  }
}
