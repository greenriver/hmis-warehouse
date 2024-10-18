window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('role-manager', class extends Stimulus.Controller {
  static get targets() {
    return [
      'permissionCategory',
      'roleToggle',
      'roleColumn',
      'individualPermission',
      'inputWrapper',
      'changeCount',
      'changeButton',
      'searchInput',
      'administrativeFilter',
      'administrativeInput',
      'subCategoryWrapper'
    ]
  }
  // This version of stimulus doesn't seem to support values
  // static values = {
  //   category: String,
  //   role: Integer
  // }


  connect() {
    this.element['roleManager'] = this // allow access to this controller from other controllers
    // console.log('role manager connected', this.roleToggleTargets)
    this.path = $(this.inputWrapperTarget).data('roleManagerFormValue')
    this.columnStateKey = 'roleManagerState'
    this.enabledColumns = []
    this.enabledColumns = this.setInitialColumns()
    console.log(this.enabledColumns);

    this.setInitialState()
  }

  toggleSection(e) {
    const target_category = $(e.currentTarget).data('roleManagerCategoryValue')
    // find all of the sections with the same value and set their state to match
    this.permissionCategoryTargets.forEach((section) => {
      const section_category = $(section).data('roleManagerCategoryValue')
      const current_panel = $(e.currentTarget).siblings('.panel-collapse')
      if (section != e.currentTarget && section_category == target_category) {
        // show class is added AFTER the opening has completed, so check for the inverse
        if ($(current_panel).hasClass('show')) {
          $(section).siblings('.panel-collapse').collapse('hide')
        } else {
          $(section).siblings('.panel-collapse').collapse('show')
        }
      }
    });
  }

  toggleColumn(e) {
    const target = $(e.currentTarget)
    const target_role = target.data('roleManagerRoleValue')
    const input = $(target).find('input')

    // toggle the visibility of the associated roleColumn
    if($(input).val() == 'show') {
      this.enabledColumns.push(target_role)
      this.roleColumnTargets.forEach((column) => {
        if (target_role == $(column).data('roleManagerRoleValue')) {
          $(column).removeClass('hide')
        }
        const search_string = $('.j-table__search').val().toLowerCase()
        this.showSearchPermissions(search_string, false)
      });
    } else {
      //FIXME: this isn't correctly removing the target role
      this.enabledColumns = this.enabledColumns.splice(this.enabledColumns.indexOf(target_role), 1)
      this.roleColumnTargets.forEach((column) => {
        if (target_role == $(column).data('roleManagerRoleValue')) {
          $(column).addClass('hide')
        }
      });
    }
    this.storeColumnState()
  }

  storeColumnState() {
    window.localStorage.setItem(this.columnStateKey, JSON.stringify(this.enabledColumns));
  }

  toggleAdmin(e) {
    const target = $(e.currentTarget)
    const input = $(target).find('input')
    // toggle the visibility of the associated administrative items
    if ($(input).val() == 'show') {
      $(this.administrativeInputTargets).removeClass('hide')
    } else {
      $(this.administrativeInputTargets).addClass('hide')
    }
  }

  searchPermissions(e) {
    const target = $(e.currentTarget)
    const search_string = target.val().toLowerCase()
    this.showSearchPermissions(search_string)
  }

  showSearchPermissions(search_string, reset=true) {
    // if we have more than three characters
    // 1. Expand all sections
    // 2. hide any permission where the search string doesn't exit in the text
    if (search_string.length > 2) {
      this.permissionCategoryTargets.forEach((section) => {
        $(section).siblings('.panel-collapse').collapse('show')
      });
      $(this.subCategoryWrapperTargets).removeClass('hide')

      this.individualPermissionTargets.forEach((permission) => {
        const wrapper = $(permission).closest('.form-check')
        const sub_category = $(permission).closest('.sub-category-wrapper').find('.sub-category-title')
        const permission_text = wrapper.text().toLowerCase() + sub_category.text().toLowerCase()
        if (permission_text.indexOf(search_string) == -1) {
          wrapper.addClass('hide')
        } else {
          wrapper.removeClass('hide')
        }
      });
      this.subCategoryWrapperTargets.forEach((section) => {
        if($(section).find('.c-checkbox:visible').length > 0) {
          $(section).removeClass('hide')
        } else {
          $(section).addClass('hide')
        }
      });
    } else if(reset) {
      this.permissionCategoryTargets.forEach((section) => {
        $(section).siblings('.panel-collapse').collapse('hide')
      });
      this.individualPermissionTargets.forEach((permission) => {
        $(permission).closest('.form-check').removeClass('hide')
      })
      $(this.subCategoryWrapperTargets).removeClass('hide')
    }
  }

  // find all inputs in the form, store key value pairs for later comparision
  setInitialState() {
    this.initialState = {}
    this.setState(this.initialState)
  }

  valueForTarget(t) {
    return $(t).data('roleManagerRoleValue')
  }

  // enable columns that were previously enabled
  setInitialColumns() {
    let visibleColumns = JSON.parse(window.localStorage.getItem(this.columnStateKey)) || $(this.roleToggleTargets).map((i) => {
      if(i > 5 || i % 2 == 1) {
        return
      }
      return this.valueForTarget(this.roleToggleTargets[i])
    }).get()
    $(this.roleToggleTargets).each((i) => {
      if (i % 2 == 1) {
        return
      }
      const target = $(this.roleToggleTargets[i])

      if(visibleColumns.includes(this.valueForTarget(target))) {
        this.toggleColumn({ currentTarget: target })
        $(target).find('input').attr('checked', 'checked')
        $(target).next().find('input').removeAttr('checked')
      }
    })

    return visibleColumns;
  }

  setState(variable) {
    const inputs = $(this.roleColumnTargets).find('input')
    $(inputs).each((i) => {
      const input = inputs[i]
      // console.log(inputs[i])
      if ($(input).is(':checked')) {
        variable[$(input).attr('name')] = '1'
      } else {
        variable[$(input).attr('name')] = '0'
      }
    })
  }

  // Collect all form fields, determine if any have changed from their initial state
  // make note by enabling the save button and count of changes if there are any
  updateState(e) {
    this.currentState = {}
    this.setState(this.currentState)
    this.updateUi()
  }

  updateUi() {
    let changed = 0
    $.each(this.currentState, (key, value) => {
      const input = $(`input[name="${key}"]`)
      const input_status = input.closest('.form-check').find('.input-status')
      const dirty_note = '<div class="dirty-note d-flex"><div class="ml-auto"><i>change pending</i></div></div>';
      if (this.initialState[key] != value) {
        changed += 1
        input.addClass('dirty')
        // ensure we only get the pending note once
        input_status.find('.dirty-note').remove()
        input_status.append(dirty_note)
      }
      else {
        input.removeClass('dirty')
        input_status.find('.dirty-note').remove()
      }
    })
    if (changed == 0) {
      $(this.changeCountTarget).text('')
      $(this.changeButtonTarget).addClass('hide')
    } else if (changed == 1) {
      $(this.changeCountTarget).text(`${changed} change pending`)
      $(this.changeButtonTarget).removeClass('hide')
    } else {
      $(this.changeCountTarget).text(`${changed} changes pending`)
      $(this.changeButtonTarget).removeClass('hide')
    }
  }
});
