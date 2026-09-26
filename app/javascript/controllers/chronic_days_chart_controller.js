import { Controller } from "@hotwired/stimulus"

// Draws the chronic days chart in clients/rollup/_chronic_days.
export default class extends Controller {
  static values = { url: String }

  connect() {
    new App.ChartsScatterByDate.ChronicForClient($(this.element), this.urlValue).load()
  }
}
