import { Controller } from "@hotwired/stimulus"

// Manages the split-checkbox / receiver-radio / submit-button interactions on
// the client Merge tab's split form (app/views/clients/_unmerge_form.haml).
export default class extends Controller {
  static targets = ["splitCheckbox", "submitButton"]

  connect() {
    this.submitButtonTarget.disabled = true
  }

  toggleReceiver(event) {
    const row = event.target.closest("tr")
    const radio = row && row.querySelector('input[type="radio"]')
    if (radio) {
      radio.disabled = !event.target.checked
      if (!event.target.checked) radio.checked = false
    }
    this.updateSubmitState()
  }

  updateSubmitState() {
    const anyChecked = this.splitCheckboxTargets.some((checkbox) => checkbox.checked)
    this.submitButtonTarget.disabled = !anyChecked
  }
}
