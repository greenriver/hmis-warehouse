import { Controller } from "@hotwired/stimulus"

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
    "month",
    "day",
    "year",
    "validationMessage",
  ]

  static values = {
    displayPattern: String,
    locale: String,
  }

  connect() {
    this.dateOptions = this.parseDateOptions()
    this.lastEmittedValue = this.hiddenInputTarget.value || ""

    this.populateSegmentsFromHidden()
    this.syncHiddenValue()
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

  populateSegmentsFromHidden() {
    if (!this.hasMonthTarget || !this.hasDayTarget || !this.hasYearTarget) return

    const currentValues = {
      month: this.monthTarget.value,
      day: this.dayTarget.value,
      year: this.yearTarget.value,
    }

    if (currentValues.month || currentValues.day || currentValues.year) {
      return
    }

    const parsed = this.parseHiddenValue()
    if (!parsed) return

    this.monthTarget.value = this.pad(parsed.month)
    this.dayTarget.value = this.pad(parsed.day)
    this.yearTarget.value = parsed.year.toString()
  }

  parseHiddenValue() {
    const value = (this.hiddenInputTarget.value || "").trim()
    if (!value) return null

    return this.parseDateString(value)
  }

  handleSegmentInput(event) {
    const input = event.target
    const sanitized = input.value.replace(/[^0-9]/g, "")
    const maxLength = Number(input.getAttribute("maxlength") || sanitized.length)
    const trimmed = sanitized.slice(0, maxLength)

    input.value = trimmed

    if (
      trimmed.length === maxLength &&
      event.inputType !== "deleteContentBackward" &&
      event.inputType !== "deleteContentForward"
    ) {
      this.focusNextSegment(input)
    }

    this.syncHiddenValue()
  }

  handleSegmentBlur(event) {
    const input = event.target
    const digits = input.value.replace(/[^0-9]/g, "")

    if (!digits) {
      input.value = ""
      this.syncHiddenValue()
      return
    }

    if (input === this.yearTarget) {
      const expanded = this.expandYear(digits)
      input.value = expanded ? expanded.toString() : digits
    } else {
      input.value = this.pad(digits)
    }

    this.syncHiddenValue()
  }

  handleSegmentKeydown(event) {
    if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return

    event.preventDefault()

    const input = event.target
    const increment = event.key === "ArrowUp" ? 1 : -1
    const bounds = this.boundsForInput(input)
    const current = parseInt(input.value, 10) || 0

    let next = current + increment

    if (bounds) {
      next = Math.min(bounds.max, Math.max(bounds.min, next))
    }

    if (input === this.yearTarget) {
      input.value = next.toString()
    } else {
      input.value = this.pad(next)
    }

    this.syncHiddenValue()
  }

  boundsForInput(input) {
    if (input === this.monthTarget) return { min: 1, max: 12 }
    if (input === this.dayTarget) return { min: 1, max: 31 }

    if (input === this.yearTarget) {
      const min = this.optionValue(["minYear", "min_year"], 1900)
      const max = this.optionValue(["maxYear", "max_year"], new Date().getFullYear() + 100)
      return { min, max }
    }

    return null
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

  focusNextSegment(input) {
    if (input === this.monthTarget && this.hasDayTarget) {
      this.dayTarget.focus()
    } else if (input === this.dayTarget && this.hasYearTarget) {
      this.yearTarget.focus()
    }
  }

  syncHiddenValue() {
    const month = this.normalizeNumber(this.monthTarget?.value)
    const day = this.normalizeNumber(this.dayTarget?.value)
    const year = this.normalizeYear(this.yearTarget?.value)

    if (!month && !day && !year) {
      this.clearHiddenValue()
      this.showValidationMessage("")
      return
    }

    if (!(month && day && year)) {
      this.clearHiddenValue()
      this.showValidationMessage("Enter month, day, and year")
      return
    }

    const date = this.buildDate(year, month, day)

    if (!date || !this.dateMatches(date, { year, month, day })) {
      this.clearHiddenValue()
      this.showValidationMessage("Date is not valid")
      return
    }

    const formatted = this.formatDisplayValue(date)
    this.hiddenInputTarget.value = formatted
    this.showValidationMessage("")

    if (formatted !== this.lastEmittedValue) {
      this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.lastEmittedValue = formatted
    }
  }

  clearHiddenValue() {
    if (this.hiddenInputTarget.value !== "") {
      this.hiddenInputTarget.value = ""
      this.hiddenInputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.lastEmittedValue = ""
    }
  }

  normalizeNumber(value) {
    if (!value) return null
    const digits = value.toString().replace(/[^0-9]/g, "")
    if (!digits) return null
    return parseInt(digits, 10)
  }

  normalizeYear(value) {
    if (!value) return null
    const digits = value.toString().replace(/[^0-9]/g, "")
    if (!digits) return null
    return this.expandYear(digits)
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
    ;[this.monthTarget, this.dayTarget, this.yearTarget].forEach((field) => {
      if (field) field.setAttribute("aria-invalid", value)
    })
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

  pad(value) {
    const number = typeof value === "number" ? value : parseInt(value || "", 10)
    if (Number.isNaN(number)) return ""
    return number.toString().padStart(2, "0")
  }
}
