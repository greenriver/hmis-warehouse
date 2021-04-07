window.App.Form = window.App.Form || {}

App.Form.Select2Input = class Select2Input {
  constructor(element, options={}) {
    let field = null
    if (typeof(element) === 'string') {
      field = document.getElementById(element)
    } else {
      field = element
    }
    if (!field) {
      console.debug(`Select2Input could not find element: ${element}`)
    } else {
      this.select = field
      this.$select = $(field)
      this.$select2Container = this.$select.next('.select2-container')

      // Add options based on use-case
      // CoCs get special functionality "My Coc (MA-500)" becomes MA-500 when selected
      if (field.classList.contains('select2-parenthetical-when-selected')) {
        options.templateSelection = (selected) => {
          if (!selected.id) {
            return selected.text
          }
          // use the parenthetical text to keep the select smaller
          const matched = selected.text.match(/\((.+?)\)/)
          if (matched && !matched.length == 2) {
            return selected.text
          } else if (matched && matched.length) {
            return matched[1]
          } else {
            return selected.text
          }
        }
      }

      if (field.classList.contains('select2-id-when-selected')) {
        options.templateSelection = (selected) => {
          if (!selected.id) {
            return selected.text
          }
          // use the code to keep the select smaller
          return selected.id
        }
      }

      // Add select all functionality if has `multiple` attribute
      if (field.hasAttribute('multiple')) {
        options.closeOnSelect = false
        this.$select.select2(options)
        this.initToggleSelectAll()
      } else {
        this.$select.select2(options)
      }

      // Parenthetical
      $(".select2-search__field").attr('aria-label', 'Search')

    }
  }

  getGroupSelectors() {
    const resultsId = `select2-${this.select.id}-results`
    return {
      groupSelector: `#${resultsId} .select2-results__group`,
      resultsId,
    }
  }

  selectAllHtml() {
    let text = 'all'
    if (this.someItemsSelected() || this.allItemsSelected()) {
      text = 'none'
    }
    return `<span class='mr-2'>Select ${text}</span>`
  }

  numberOfSelectedItems() {
    return this.$select.find('option:selected').length
  }

  someItemsSelected() {
    return this.numberOfSelectedItems() && !this.allItemsSelected()
  }

  allItemsSelected() {
    return this.numberOfSelectedItems() === this.$select.find('option').length && this.$select.find('option').length > 0
  }

  noneSelected() {
    return (this.$formGroup.find('select').val() === 0) ||
      (this.$select.select2('data').length === 0)
  }


  initToggleSelectAll() {
    // Init optgroup select all
    const self = this
    const { resultsId, groupSelector } =  this.getGroupSelectors()
    $(document).on('click', groupSelector, function() {
      const label = this.parentElement.getAttribute('aria-label')
      const selected = !!this.dataset.allSelected
      self.$select.find('option').each((i, option) => {
        if (!option.parentElement.label.match(label)) return
        $(option).prop('selected', selected ? null : 'selected')
      })
      if (this.dataset.allSelected) {
        this.removeAttribute('data-all-selected')
      } else {
        this.setAttribute('data-all-selected', true)
      }
      // Trigger change on the select2 instance so items are added/subtracted
      self.$select.trigger("change")
      // Update class of list items so they are visually highlighted
      $(`#${resultsId} .select2-results__options--nested  li`).each((i, el) => {
        el.setAttribute('aria-selected', !selected)
      })
    });

    // Init external select all items
    this.$formGroup = this.$select.closest('.form-group')
    this.$formGroup.addClass('select2-wrapper')
    const $label = this.$formGroup.find('> label')
    const $labelWrapper = $("<div class='select2__label-wrapper'></div>")
    // Add select all/none link to select2 input
    $labelWrapper.append($(`
      <div class="select2-select-all j-select2-select-all">
        ${this.selectAllHtml()}
      </div>
    `))
    // only add it if we don't already have it
    if(this.$formGroup.find('.j-select2-select-all').length == 0) {
      $label.prependTo($labelWrapper)
      this.$formGroup.prepend($labelWrapper)
    }

    // Init events on select2
    // Trigger toggle on manual update: 'select2:select select2:unselect
    // Trigger toggle on select all/ none click: '.j-select2-select-all'
    this.$select.closest('.form-group')
      .on('click', '.j-select2-select-all', this.toggleSelectAll.bind(this, false))
    this.$select.on('select2:select select2:unselect', this.toggleSelectAll.bind(this, true))

    // Initial state based on existing options
    this.allItemsAreSelected = this.numberOfSelectedItems()
  }

  toggleSelectAll(isManualChange=false) {
    if (!isManualChange) {
      this.$select.find('option').prop('selected', !this.allItemsAreSelected)
      this.allItemsAreSelected = !this.allItemsAreSelected
    } else {
      if (this.someItemsSelected() || this.allItemsSelected()) {
        this.allItemsAreSelected = true
      } else {
        this.allItemsAreSelected = false
      }
    }
    this.$select.trigger('change')

    // Update DOM element to reflect selections
    const $selectAllLink = this.$formGroup.find('.select2-select-all')
    // this.$select2Container[classAction]('all-selected')
    let html = this.selectAllHtml()
    if (this.allItemsSelected() || this.numberOfSelectedItems()) {
      html = this.selectAllHtml()
    }
    $selectAllLink.html(html)
  }

}
