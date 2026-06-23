import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['lastUpdate']
  }

  static get values() {
    return { url: String }
  }

  toggle(event) {
    const checked = event.target.checked
    const message = checked
      ? 'Are you sure you want to exclude this client from external data sharing? Their data will no longer appear in external exports.'
      : 'Are you sure you want to remove this client from the external data sharing exclusion list? This may result in their data being shared externally.'

    if (!window.confirm(message)) {
      event.target.checked = !checked
      return
    }

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    const body = new FormData()
    if (checked) body.append('exclude_from_external_data_sharing', '1')

    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        Accept: 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body,
    })
      .then(response => {
        if (!response.ok) throw new Error('Request failed')
        return response.json()
      })
      .then(data => {
        if (this.hasLastUpdateTarget) this.lastUpdateTarget.textContent = data.last_updated || ''
      })
      .catch(() => {
        event.target.checked = !checked
      })
  }
}
