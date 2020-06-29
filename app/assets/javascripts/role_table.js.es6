window.App.RoleTable = class TableSearch {
  constructor(props) {
    this.isDirty = false
    this.props = Object.assign({
      tableContainerSelector: '.j-table',
      submitContainerSelector: '.j-table__submit-container',
      tableObjectHeadingSelector: '.j-table__object',
      tableInputSelector: '.j-table__input',
      tableCancelChange: '.j-table__cancel',
    }, props)

    this.isSaving = false
    this.$tableContainer = $(this.props.tableContainerSelector)
    this.init()
  }

  init() {
    // Declare variables with defaults
    const {
      tableSelector='.j-table__table',
      tableSearchInputSelector='.j-table__search',
      tableRowSelector='.j-table__row',
      submitActionSelector= '.j-table__submit-changes',
      tableCancelChange
    } = this.props

    // Init Datable
    this.table = $(tableSelector).DataTable({
      // scrollY: '55vh',
      scrollCollapse: true,
      scrollX: true,
      searching: false,
      ordering: false,
      paging: false,
      bInfo: false,
      // fixedHeader: true,
      fixedColumns: {
        leftColumns: 1
      }
    });

    // Init Table search
    new App.TableSearch({
      inputClass: tableSearchInputSelector,
      rowClass: tableRowSelector
    })

    // Register events
    $(submitActionSelector).click(this.submitChanges.bind(this))
    $(`${tableSelector} input`).on('change', this.changeDirtyState.bind(this, true))
    $(tableCancelChange).click(() => {
      this.isDirty = false
      return
    })
    window.onbeforeunload = () => {
      if (this.isDirty) {
        return 'Looks like there are unsaved changes. Those changes will be lost if you navigate away'
      }
    }
  }

  submitChanges() {
    $(this.submitActionSelector).blur()
    if (this.isSaving) return
    this.saving()
    const {
      tableContainerSelector,
      tableObjectHeadingSelector,
      tableInputSelector,
    } = this.props
    const rolePromises =
      this.$tableContainer.data('objects')
        .map((id, i) => {
          const inputBaseQuery = `${tableInputSelector}[data-role=${id}] input`
          const inputs = this.$tableContainer.find(`${inputBaseQuery}.dirty`)
          if (inputs.length) {
            inputs.add(`${tableContainerSelector} input[name=authenticity_token]`)
            return $.ajax({
              type: 'PATCH',
              dataType: 'JSON',
              url: `/admin/roles/${id}`,
              data: this.$tableContainer.find(inputBaseQuery).serialize(),
            })
          } else {
            return null
          }
        })
    Promise.all(rolePromises)
      .then(() => {
        this.confirmSaved()
      }).catch((error) => {
        this.confirmSaved(error)
      })
  }

  changeDirtyState(isDirty=true, event) {
    this.isDirty = isDirty
    if (event) {
      event.target.classList.add('dirty')
    }
    else if (!isDirty) {
      this.$tableContainer.find('input.dirty').removeClass('dirty')
    }
    const $submitContainer = $(this.props.submitContainerSelector)
    if ($submitContainer.length) {
      if (isDirty) {
        $submitContainer.addClass('show')
      }
      else {
        $submitContainer.removeClass('show')
      }
    }
  }

  saving() {
    this.isSaving = true
    $(this.submitActionSelector).attr('disabled', true)
    this.$tableContainer.prepend(`
      <div class="j-table__loading c-save-table__loading">
        <div>
          <span>Saving</span>
          <div class="c-loading c-loading--lg c-loading--dark">
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
            <div class="c-loading__dot"></div>
          </div>
        <div>
      </div>
    `)
  }

  confirmSaved(error=null) {
    this.isSaving = false
    const $loading = this.$tableContainer.find('.j-table__loading')
    $(this.submitActionSelector).attr('disabled', false)
    if (!error) {
      // Show confirmation message
      setTimeout(() => {
        this.changeDirtyState(false)
        $(this.props.submitContainerSelector).removeClass('show')
      }, 500)
      // Remove loading elements
      this.isDirty = false
    } else {
      console.error('Roles/permissions update failed', error)
      const $container = $(this.props.submitContainerSelector)
      $container.find('.c-save-table__submit-container-error-text').html(`
        <span>
          We're having trouble saving your changes. Please try again.
        </span>
      `)
      $container.addClass('has-error')
    }
    setTimeout(() => { $loading.fadeOut() }, 500)
  }
}
