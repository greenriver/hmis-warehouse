import { Controller } from "@hotwired/stimulus"
import Inputmask from "inputmask"

const MONTHS = [
  "Jan",
  "Feb",
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec",
]

// Connects to data-controller="datepicker2"
export default class extends Controller {
  static targets = [
    "hiddenInput",
    "maskedInput",
    "validationMessage",
  ]

  static values = {
    displayPattern: String,
    locale: String,
  }

  connect() {
    this.dateOptions = this.parseDateOptions()
    this.initMaskedInput()
    this.lastEmittedValue = this.hiddenInputTarget.value || ""

    this.populateMaskedFromHidden()
    this.syncHiddenValue({ emitChange: false })
  }

  parseDateOptions() {
    const raw = this.element.dataset.dateOptions
    if (!raw) return {}

    try {
      return JSON.parse(raw)
    } catch (_error) {
      return {}
    }
  }

  initMaskedInput() {
    if (!this.hasMaskedInputTarget) return

    this.inputMask = new Inputmask({
      mask: "99/99/9999",
      placeholder: "MM/DD/YYYY",
      showMaskOnHover: false,
      showMaskOnFocus: true,
      clearIncomplete: false,
    })

    this.inputMask.mask(this.maskedInputTarget)
  }

  populateMaskedFromHidden() {
    if (!this.hasMaskedInputTarget) return

    const parsed = this.parseHiddenValue()
    if (!parsed) return

    const formatted = this.formatMMDDYYYY(parsed)
    if (formatted) this.maskedInputTarget.value = formatted
  }

  parseHiddenValue() {
    const value = (this.hiddenInputTarget.value || "").trim()
    if (!value) return null

    return this.parseDateString(value)
  }

  handleMaskedInput() {
    this.syncHiddenValue()
  }

  handleMaskedBlur() {
    this.syncHiddenValue()
  }

  optionValue(keys, fallback) {
    if (!this.dateOptions) return fallback
    for (const key of keys) {
      if (Object.prototype.hasOwnProperty.call(this.dateOptions, key)) {
        return this.dateOptions[key]
      }
    }
    return fallback
  }

  syncHiddenValue({ emitChange = true } = {}) {
    if (!this.hasMaskedInputTarget) return

    const raw = (this.maskedInputTarget.value || "").trim()
    const digitsOnly = raw.replace(/[^0-9]/g, "")

    if (!digitsOnly) {
      this.clearHiddenValue({ emitChange })
      this.showValidationMessage("")
      return
    }

    if (digitsOnly.length !== 8) {
      this.clearHiddenValue({ emitChange })
      this.showValidationMessage("Enter a valid date")
      return
    }

    const parts = this.parseMMDDYYYY(raw)
    if (!parts) {
      this.clearHiddenValue({ emitChange })
      this.showValidationMessage("Enter a valid date")
      return
    }

    const { month, day, year } = parts
    const date = this.buildDate(year, month, day)

    if (!date || !this.dateMatches(date, parts) || !this.yearWithinBounds(year)) {
      this.clearHiddenValue({ emitChange })
      this.showValidationMessage("Date is not valid")
      return
    }

    const formatted = this.formatDisplayValue(date)
    this.hiddenInputTarget.value = formatted
    this.showValidationMessage("")

    if (formatted !== this.lastEmittedValue && emitChange) {
      this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    }

    this.lastEmittedValue = formatted
  }

  clearHiddenValue({ emitChange = true } = {}) {
    if (this.hiddenInputTarget.value !== "") {
      this.hiddenInputTarget.value = ""
      if (emitChange) {
        this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      }
      this.lastEmittedValue = ""
    }
  }

  buildDate(year, month, day) {
    if (!year || !month || !day) return null
    const date = new Date(year, month - 1, day)
    if (Number.isNaN(date.getTime())) return null
    return date
  }

  dateMatches(date, { year, month, day }) {
    return (
      date.getFullYear() === year &&
      date.getMonth() + 1 === month &&
      date.getDate() === day
    )
  }

  formatDisplayValue(date) {
    const monthName = MONTHS[date.getMonth()]
    return `${monthName} ${date.getDate()}, ${date.getFullYear()}`
  }

  formatMMDDYYYY({ year, month, day }) {
    const mm = month.toString().padStart(2, "0")
    const dd = day.toString().padStart(2, "0")
    return `${mm}/${dd}/${year}`
  }

  showValidationMessage(message) {
    if (!this.hasValidationMessageTarget) return

    if (message) {
      this.validationMessageTarget.textContent = message
      this.validationMessageTarget.classList.remove("d-none")
      this.updateAriaValidity(false)
    } else {
      this.validationMessageTarget.textContent = ""
      this.validationMessageTarget.classList.add("d-none")
      this.updateAriaValidity(true)
    }
  }

  updateAriaValidity(isValid) {
    const value = isValid ? "false" : "true"
    if (this.hasMaskedInputTarget) {
      this.maskedInputTarget.setAttribute("aria-invalid", value)
    }
  }

  parseDateString(value) {
    const text = value.trim()
    if (!text) return null

    const monthMatch = text.match(/^([A-Za-z]{3})\s+(\d{1,2}),\s*(\d{4})$/)
    if (monthMatch) {
      const monthIndex = MONTHS.findIndex(
        (name) => name.toLowerCase() === monthMatch[1].toLowerCase(),
      )
      if (monthIndex >= 0) {
        return {
          month: monthIndex + 1,
          day: parseInt(monthMatch[2], 10),
          year: parseInt(monthMatch[3], 10),
        }
      }
    }

    const isoMatch = text.match(/^(\d{4})[-/](\d{2})[-/](\d{2})$/)
    if (isoMatch) {
      return {
        year: parseInt(isoMatch[1], 10),
        month: parseInt(isoMatch[2], 10),
        day: parseInt(isoMatch[3], 10),
      }
    }

    const shortYearMatch = text.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{2})$/)
    if (shortYearMatch) {
      const month = parseInt(shortYearMatch[1], 10)
      const day = parseInt(shortYearMatch[2], 10)
      const year = this.expandYear(shortYearMatch[3])
      return { month, day, year }
    }

    const usMatch = text.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$/)
    if (usMatch) {
      return {
        month: parseInt(usMatch[1], 10),
        day: parseInt(usMatch[2], 10),
        year: parseInt(usMatch[3], 10),
      }
    }

    const parsed = new Date(text)
    if (!Number.isNaN(parsed.getTime())) {
      return {
        year: parsed.getFullYear(),
        month: parsed.getMonth() + 1,
        day: parsed.getDate(),
      }
    }

    return null
  }

  parseMMDDYYYY(value) {
    if (!value) return null
    const digits = value.toString().replace(/[^0-9]/g, "")
    if (digits.length !== 8) return null

    const month = parseInt(digits.slice(0, 2), 10)
    const day = parseInt(digits.slice(2, 4), 10)
    const year = parseInt(digits.slice(4), 10)

    if (Number.isNaN(month) || Number.isNaN(day) || Number.isNaN(year)) return null
    if (month < 1 || month > 12) return null
    if (day < 1 || day > 31) return null

    return { month, day, year }
  }

  expandYear(value) {
    const digits = value.toString().slice(0, 4)
    if (digits.length <= 2) {
      const number = parseInt(digits, 10)
      if (Number.isNaN(number)) return null
      const defaultPivot = new Date().getFullYear() % 100
      const centuryPivot = this.optionValue(["twoDigitYearPivot", "two_digit_year_pivot"], defaultPivot)
      const century = number <= centuryPivot ? 2000 : 1900
      return century + number
    }

    const number = parseInt(digits, 10)
    if (Number.isNaN(number)) return null
    return number
  }

  yearWithinBounds(year) {
    const minYear = this.optionValue(["minYear", "min_year"], null)
    const maxYear = this.optionValue(["maxYear", "max_year"], null)

    if (minYear && year < minYear) return false
    if (maxYear && year > maxYear) return false

    return true
  }
}
