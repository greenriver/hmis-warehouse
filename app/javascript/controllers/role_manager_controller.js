import { Controller } from "@hotwired/stimulus"

// This controller is loaded on-demand and registers itself with the global Stimulus application
// It assumes that `window.Stimulus` has been initialized by `application_esbuild.js`

const controller = class extends Controller {
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
    this.element['roleManager'] = this
    this.path = $(this.inputWrapperTarget).data('roleManagerFormValue')
    this.columnStateKey = 'roleManagerState' + this.path
    this.enabledColumns = []
    this._syncingCategory = false
    this.categoryState = {}
    this.enabledColumns = this.setInitialColumns()
    this.setInitialState()
    this.bindCollapseSyncListeners()
  }

  // Sync same-category panels across role columns. Uses native addEventListener
  // because Bootstrap 5 fires CustomEvents with type "show.bs.collapse" — jQuery's
  // .on() strips the namespace and listens for "show", which never matches.
  bindCollapseSyncListeners() {
    this.permissionCategoryTargets.forEach((button) => {
      const panel = $(button).siblings('.panel-collapse')[0]
      if (!panel) return
      panel.addEventListener('show.bs.collapse', () => this._syncCategory(button, 'show'))
      panel.addEventListener('hide.bs.collapse', () => this._syncCategory(button, 'hide'))
    })
  }

  _syncCategory(sourceButton, action) {
    if (this._syncingCategory) return
    this._syncingCategory = true
    const category = $(sourceButton).data('roleManagerCategoryValue')
    this.categoryState[category] = action
    this.permissionCategoryTargets.forEach((button) => {
      if (button === sourceButton) return
      if ($(button).data('roleManagerCategoryValue') !== category) return
      const $panel = $(button).siblings('.panel-collapse')
      if (!$panel.length) return
      if (action === 'show' && !$panel.hasClass('show')) {
        $panel.collapse('show')
      } else if (action === 'hide' && $panel.hasClass('show')) {
        $panel.collapse('hide')
      }
    })
    this._syncingCategory = false
  }

  toggleColumn(e) {
    const input = $(e.currentTarget)
    const target_role = input.data('roleManagerRoleValue')

    if (input.is(':checked')) {
      this.showColumn(target_role)
    } else {
      this.hideColumn(target_role)
    }
    this.storeColumnState()
  }

  showColumn(target_role) {
    if (!this.enabledColumns.includes(target_role)) {
      this.enabledColumns.push(target_role)
    }
    this.roleColumnTargets.forEach((column) => {
      if (target_role == $(column).data('roleManagerRoleValue')) {
        $(column).removeClass('hide')
      }
    })
    this._applyCategoryStateToColumn(target_role)
    const search_string = $('.j-table__search').val().toLowerCase()
    this.showSearchPermissions(search_string, false)
  }

  _applyCategoryStateToColumn(target_role) {
    const prev = this._syncingCategory
    this._syncingCategory = true
    this.permissionCategoryTargets.forEach((button) => {
      if ($(button).closest('[data-role-manager-role-value]').data('roleManagerRoleValue') != target_role) return
      const storedAction = this.categoryState[$(button).data('roleManagerCategoryValue')]
      if (!storedAction) return
      const $panel = $(button).siblings('.panel-collapse')
      if (!$panel.length) return
      if (storedAction === 'show' && !$panel.hasClass('show')) {
        $panel.collapse('show')
      } else if (storedAction === 'hide' && $panel.hasClass('show')) {
        $panel.collapse('hide')
      }
    })
    this._syncingCategory = prev
  }

  hideColumn(target_role) {
    this.enabledColumns = this.enabledColumns.filter(element => element !== target_role)
    this.roleColumnTargets.forEach((column) => {
      if (target_role == $(column).data('roleManagerRoleValue')) {
        $(column).addClass('hide')
      }
    });
  }

  storeColumnState() {
    window.localStorage.setItem(this.columnStateKey, JSON.stringify(this.enabledColumns));
  }

  fetchColumnState() {
    try {
      return JSON.parse(window.localStorage.getItem(this.columnStateKey));
    } catch (error) {
      console.error('Error parsing localStorage item:', error);
    }
  }

  toggleAdmin(e) {
    const input = $(e.currentTarget)
    // toggle the visibility of the associated administrative items
    if (input.is(':checked')) {
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

  showSearchPermissions(search_string, reset = true) {
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
        if ($(section).find('.c-checkbox:visible').length > 0) {
          $(section).removeClass('hide')
        } else {
          $(section).addClass('hide')
        }
      });
    } else if (reset) {
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
    // By default, show the first 3 roles
    let visibleColumns = this.fetchColumnState() || this.roleToggleTargets.slice(0, 3).map((target) => this.valueForTarget(target));

    this.enabledColumns = [];

    this.roleToggleTargets.forEach((toggle) => {
      const input = $(toggle);
      const roleValue = this.valueForTarget(input);

      if (visibleColumns.includes(roleValue)) {
        input.prop('checked', true);
        this.showColumn(roleValue);
      } else {
        input.prop('checked', false);
        this.hideColumn(roleValue);
      }
    });

    this.storeColumnState();
    return this.enabledColumns;
  }

  setState(variable) {
    const inputs = $(this.roleColumnTargets).find('input')
    $(inputs).each((i) => {
      const input = inputs[i]
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
      $(this.changeCountTargets).text('')
      $(this.changeButtonTargets).addClass('hide')
    } else if (changed == 1) {
      $(this.changeCountTargets).text(`${changed} change pending`)
      $(this.changeButtonTargets).removeClass('hide')
    } else {
      $(this.changeCountTargets).text(`${changed} changes pending`)
      $(this.changeButtonTargets).removeClass('hide')
    }
  }
}

export default controller

// Register the controller with the global Stimulus application
if (window.Stimulus) {
  window.Stimulus.register("role-manager", controller)
}
