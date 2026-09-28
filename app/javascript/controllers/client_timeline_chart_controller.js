import { Controller } from "@hotwired/stimulus"

// Draws the enrollment timeline in overlapping_coc_utilization/_client_card.
export default class extends Controller {
  static values = { enrollments: Array, domain: Array, cocs: Array }

  connect() {
    App.WarehouseReports.clientTimelineChart({
      enrollments: this.enrollmentsValue,
      rootSelector: `#${this.element.id}`,
      domain: this.domainValue,
      cocs: this.cocsValue,
    })
  }
}
