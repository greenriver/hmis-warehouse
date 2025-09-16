// This supports the role table on the admin/health/roles page, not the main or HMIS roles pages
import { Controller } from "@hotwired/stimulus"
import DataTable from 'datatables.net-bs5'

export default class extends Controller {
  static get targets() {
    return [
      'table',
      'searchInput',
      'tableRow',
      'submitButton',
      'cancelButton',
      'submitContainer',
      'loading'
    ]
  }

  static get values() {
    return {
      patchUrl: String,
      objects: Array
    }
  }

  connect() {
    this.isDirty = false
    this.isSaving = false

    // Initialize search functionality
    this.initializeSearch()

    // Set up event listeners
    this.setupEventListeners()

    // Set up beforeunload warning
    this.setupBeforeUnload()
  }

  initializeSearch() {
    if (this.hasSearchInputTarget) {
      // Debounced search function
      this.debouncedSearch = this.debounce(this.search.bind(this), 100)

      $(this.searchInputTarget).on('input', (event) => {
        this.debouncedSearch(event.target.value)
      })
    }
  }

  search(searchTerm) {
    const term = searchTerm.toLowerCase()
    let itemsFound = 0

    this.tableRowTargets.forEach((row) => {
      const $row = $(row)
      const text = $row.text().toLowerCase()
      const matches = text.indexOf(term) !== -1

      if (matches) {
        $row.removeClass('hide')
        itemsFound++
      } else {
        $row.addClass('hide')
      }
    })

    // Show/hide no results message if it exists
    const $noItems = $(this.element).find('.j-table__no-items')
    if ($noItems.length) {
      if (itemsFound === 0) {
        $noItems.removeClass('hide')
      } else {
        $noItems.addClass('hide')
      }
    }
  }

  setupEventListeners() {
    // Submit button
    if (this.hasSubmitButtonTarget) {
      $(this.submitButtonTarget).on('click', this.submitChanges.bind(this))
    }

    // Cancel button
    if (this.hasCancelButtonTarget) {
      $(this.cancelButtonTarget).on('click', () => {
        this.isDirty = false
      })
    }

    // Input change tracking
    if (this.hasTableTarget) {
      $(this.tableTarget).find('input').on('change', (event) => {
        this.changeDirtyState(true, event)
      })
    }
  }

  setupBeforeUnload() {
    window.addEventListener('beforeunload', (event) => {
      if (this.isDirty) {
        event.preventDefault()
        event.returnValue = 'Looks like there are unsaved changes. Those changes will be lost if you navigate away'
        return event.returnValue
      }
    })
  }

  submitChanges() {
    if (this.isSaving) return

    this.saving()

    const rolePromises = this.objectsValue.map((id) => {
      const inputBaseQuery = `.j-table__input[data-role=${id}] input`
      const inputs = $(this.element).find(`${inputBaseQuery}.dirty`)

      if (inputs.length) {
        inputs.add($(this.element).find('input[name=authenticity_token]'))

        return $.ajax({
          type: 'PATCH',
          dataType: 'JSON',
          url: `${this.patchUrlValue}/${id}`,
          data: $(this.element).find(inputBaseQuery).serialize()
        })
      } else {
        return Promise.resolve(null)
      }
    })

    Promise.all(rolePromises)
      .then(() => {
        this.confirmSaved()
      })
      .catch((error) => {
        this.confirmSaved(error)
      })
  }

  changeDirtyState(isDirty = true, event) {
    this.isDirty = isDirty

    if (event) {
      event.target.classList.add('dirty')
    } else if (!isDirty) {
      $(this.element).find('input.dirty').removeClass('dirty')
    }

    if (this.hasSubmitContainerTarget) {
      const $submitContainer = $(this.submitContainerTarget)
      if (isDirty) {
        $submitContainer.addClass('show')
      } else {
        $submitContainer.removeClass('show')
      }
    }
  }

  saving() {
    this.isSaving = true

    if (this.hasSubmitButtonTarget) {
      $(this.submitButtonTarget).attr('disabled', true)
    }

    // Add loading indicator
    const loadingHtml = `
      <div class="j-table__loading c-save-table__loading">
        <div>
          <span>Saving</span>
          <div class="c-loading c-loading--lg c-loading--dark">
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
          </div>
        <div>
      </div>
    `
    $(this.element).prepend(loadingHtml)
  }

  confirmSaved(error = null) {
    this.isSaving = false
    const $loading = $(this.element).find('.j-table__loading')
    if (this.hasSubmitButtonTarget) {
      $(this.submitButtonTarget).attr('disabled', false)
    }
    if (!error) {
      setTimeout(() => {
        this.changeDirtyState(false)
        if (this.hasSubmitContainerTarget) {
          $(this.submitContainerTarget).removeClass('show')
        }
      }, 500)
      this.isDirty = false
    } else {
      console.error('Roles/permissions update failed', error)
      if (this.hasSubmitContainerTarget) {
        $(this.submitContainerTarget).find('.c-save-table__submit-container-error-text').html(`
          <span>
            We're having trouble saving your changes. Please try again.
          </span>
        `)
        $(this.submitContainerTarget).addClass('has-error')
      }
    }
    setTimeout(() => { $loading.fadeOut() }, 500)
  }

  // Utility: debounce function
  debounce(func, wait, immediate) {
    let timeout
    return function () {
      const context = this, args = arguments
      const later = function () {
        timeout = null
        if (!immediate) func.apply(context, args)
      }
      const callNow = immediate && !timeout
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)
      if (callNow) func.apply(context, args)
    }
  }
}
