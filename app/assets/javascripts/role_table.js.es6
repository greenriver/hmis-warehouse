window.App.RoleTable = class TableSearch {
  constructor(props) {
    this.isDirty = false
    this.props = Object.assign({
      tableContainerSelector: '.j-table',
      submitContainerSelector: '.j-table__submit-container',
      tableObjectHeadingSelector: '.j-table__object',
    }, props)

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
    window.onbeforeunload = () => {
      if (this.isDirty) {
        return 'Looks like there are unsaved changes. Those changes will be lost if you navigate away'
      }
    }
  }

  submitChanges() {
    this.saving()
    const {
      tableObjectHeadingSelector,
      tableInputSelector,
    } = this.props
    var rolePromises = $(tableObjectHeadingSelector)
    .toArray()
    .map( (el) => $(el).data('role') )
    .map((id) => {
      var inputData = $(`input[name=authenticity_token], ${tableInputSelector}[data-role=${id}] input`).serialize()
      return $.ajax({
        url: `/admin/roles/${id}`,
        type: 'PATCH',
        dataType: 'html',
        data: inputData,
      })
    })
    Promise.all(rolePromises)
      .then(() => {
        console.log('All Saved')
        this.confirmSaved()
      }).catch((error) => {
        this.confirmSaved()
        console.error('Save failed', error)
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
    this.$tableContainer.prepend('<div class="c-loading j-table__loading"><span>Saving</span></div>')
  }

  confirmSaved() {
    console.log('confirmed')
    const $loading = this.$tableContainer.find('.j-table__loading')
    // Show confirmation message
    setTimeout(() => {
      this.changeDirtyState(false)
      $(this.props.submitContainerSelector).removeClass('show')
      $loading.html(`
        <span style='font-size: 100px'> ✓ </span>
      `)
    }, 500)
    // Remove loading elements
    setTimeout(() => { $loading.fadeOut() }, 500)
    this.isDirty = false
  }
}
