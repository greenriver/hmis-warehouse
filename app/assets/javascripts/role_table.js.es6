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
      if (!this.isDirty) {
        return false
      } else {
        return 'Looks like there are unsaved changes. Those changes will be lost if you navigate away'
      }
    }
  }

  submitChanges() {
    this.saving()
    var rolePromises = $(this.props.tableObjectHeadingSelector)
    .toArray()
    .map( (el) => $(el).data('role') )
    .map((id) => {
      var inputData = $(`input[name=authenticity_token], .j-role-permission[data-role=${id}] input`).serialize()
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
        setTimeout(() => {
          this.confirmSaved()
          console.log('finished')
        }, 1000)
        console.error('Save failed', error)
      })
  }

  changeDirtyState(isDirty=true) {
    this.isDirty = !isDirty
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
    this.$tableContainer.prepend('<div class="j-table__loading"><span>Saving</span></div>')
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
    }, 1000)
    // Remove loading elements
    setTimeout(() => { $loading.fadeOut() }, 1000)
    this.isDirty = false
  }
}
