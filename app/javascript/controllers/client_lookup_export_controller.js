import { Controller } from "@hotwired/stimulus"

// Select2 fires its own events; `change` alone misses selections made through it.
const CHANGE_EVENTS = 'change select2:select select2:unselect select2:close'

// Selecting none of these leaves the filter matching nothing, and the export would fail
// server-side with only the modal's generic error state to show for it.
const SCOPE_FIELDS = [
  'report[data_source_ids][]',
  'report[organization_ids][]',
  'report[project_ids][]',
]

export default class extends Controller {
  static get targets() {
    return ['button', 'tooltip']
  }

  connect() {
    this.$element = window.$(this.element)
    this.onChange = () => this.refresh()
    this.$element.on(CHANGE_EVENTS, this.onChange)

    if (this.hasTooltipTarget && window.bootstrap) {
      this.tooltip = window.bootstrap.Tooltip.getOrCreateInstance(this.tooltipTarget)
    }

    this.refresh()
  }

  disconnect() {
    if (this.$element) this.$element.off(CHANGE_EVENTS, this.onChange)
    if (this.tooltip) this.tooltip.dispose()
  }

  // Keeps the button's disabled state, and the tooltip explaining it, in step with the
  // filter, so the explanation can't outlive the problem it describes.
  refresh() {
    const enabled = this.hasScope()

    if (this.hasButtonTarget) {
      this.buttonTarget.classList.toggle('disabled', !enabled)
      this.buttonTarget.setAttribute('aria-disabled', String(!enabled))
    }

    if (!this.tooltip) return

    if (enabled) {
      // hide() first: disable() alone leaves an open tooltip on screen if the user
      // satisfies the filter while hovering the button.
      this.tooltip.hide()
      this.tooltip.disable()
    } else {
      this.tooltip.enable()
    }
  }

  download(event) {
    if (!this.hasScope()) {
      event.preventDefault()
      event.stopImmediatePropagation()
      return
    }

    // jQuery's .data() cache is what documentExport.js reads, so set it through jQuery
    // rather than via setAttribute -- the latter would be ignored once .data() is warm.
    window.$(this.buttonTarget).data('query-string', this.queryString())
  }

  hasScope() {
    return this.fields().some(
      (field) => SCOPE_FIELDS.includes(field.name) && field.value !== ''
    )
  }

  queryString() {
    const params = this.fields().filter((field) => field.name.startsWith('report['))
    // cache bust so reports can be re-generated if the data changes.
    params.push({ name: 'report[generated_on]', value: this.today() })

    return window.$.param(params)
  }

  fields() {
    return window.$(this.element).serializeArray()
  }

  today() {
    const now = new Date()
    const pad = (n) => String(n).padStart(2, '0')

    return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`
  }
}
