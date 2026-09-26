import { Controller } from "@hotwired/stimulus"

// Colors the trend dots in clients/rollup/_services.
export default class extends Controller {
  static targets = ["dot"]
  static values = { dots: Object }

  connect() {
    const { points, min, max } = this.dotsValue
    this.dotTargets.forEach((td, i) => {
      $(td).append(App.util.colorDot({ point: points[i], low: min, high: max, center: true }))
    })
  }
}
