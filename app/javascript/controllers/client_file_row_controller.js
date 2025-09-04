import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="client-file-row"
export default class extends Controller {
  connect() {
    this.element.querySelectorAll('.enable-on-load').forEach((input) => {
      input.disabled = false
    })
  }
}
