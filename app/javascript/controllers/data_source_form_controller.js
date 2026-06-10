import { Controller } from "@hotwired/stimulus"

const $ = window.jQuery

// Toggles conditional sections on the data source create/edit form based on
// Open Path HMIS hostname and authoritative source settings.
export default class extends Controller {
  static targets = [
    "nonHmisQuestions",
    "authoritativeQuestions",
    "importerQuestions",
    "authoritativeType",
    "hmisHostname",
    "authoritative",
  ]

  static values = {
    hmisAssigned: Boolean,
  }

  connect() {
    this.refresh()

    if (this.hasHmisHostnameTarget) {
      this._hmisSelectHandler = () => this.refresh()
      $(this.hmisHostnameTarget).on(
        "select2:select select2:unselect select2:close change",
        this._hmisSelectHandler,
      )
    }
  }

  disconnect() {
    if (this.hasHmisHostnameTarget && this._hmisSelectHandler) {
      $(this.hmisHostnameTarget).off(
        "select2:select select2:unselect select2:close change",
        this._hmisSelectHandler,
      )
    }
  }

  refresh() {
    const hasHmis =
      this.hmisAssignedValue ||
      (this.hasHmisHostnameTarget && $(this.hmisHostnameTarget).val())
    const authoritative =
      this.hasAuthoritativeTarget && this.authoritativeTarget.checked
    const authoritativeNonHmis = authoritative && !hasHmis
    const showImporterQuestions = !authoritativeNonHmis

    this.toggleSection(this.nonHmisQuestionsTarget, !hasHmis)
    this.setInputsDisabled(this.nonHmisQuestionsTarget, hasHmis)

    if (this.hasAuthoritativeQuestionsTarget) {
      this.toggleSection(this.authoritativeQuestionsTarget, authoritativeNonHmis)
      this.setInputsDisabled(
        this.authoritativeQuestionsTarget,
        !authoritativeNonHmis,
      )
    }

    if (this.hasImporterQuestionsTarget) {
      this.toggleSection(this.importerQuestionsTarget, showImporterQuestions)
      this.setInputsDisabled(
        this.importerQuestionsTarget,
        !showImporterQuestions,
      )
    }

    if (this.hasAuthoritativeTypeTarget) {
      this.toggleSection(this.authoritativeTypeTarget, authoritative)
    }
  }

  toggleSection(element, visible) {
    $(element).toggle(visible)
  }

  setInputsDisabled(container, disabled) {
    $(container).find(":input").prop("disabled", disabled)
  }
}
