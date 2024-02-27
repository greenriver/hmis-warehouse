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
      'changeButton'
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
      this.roleColumnTargets.forEach((column) => {
        if (target_role == $(column).data('roleManagerRoleValue')) {
          $(column).removeClass('hidden')
        }
      });
    } else {
      this.roleColumnTargets.forEach((column) => {
        if (target_role == $(column).data('roleManagerRoleValue')) {
          $(column).addClass('hidden')
        }
      });
    }
  }

  // find all inputs in the form, store key value pairs for later comparision
  setInitialState() {
    this.initialState = {}
    this.setState(this.initialState)
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
      if (this.initialState[key] != value) {
        changed += 1
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

  save(e) {
    // Disabling in favor of batch saves
    // const target = $(e.currentTarget)
    // const target_role_id = target.data('roleManagerRoleValue')
    // const key = target.data('roleManagerPermissionValue')
    // const checked = $(target).is(':checked')
    // const value = checked ? '1' : '0'
    // const data = { role: { } }
    // const label = $(target).closest('.form-check').find('label').text().trim()
    // const text_value = checked ? 'Yes' : 'No'
    // data.role[key] = value
    // // console.log(target_role_id, key, checked, this.path, data)
    // $.ajax({
    //   type: 'PATCH',
    //   dataType: 'JSON',
    //   url: `${this.path}/${target_role_id}`,
    //   data: data,
    //   success: (response) => {
    //     // attach a toast to the page with a success message
    //     $('.toast-header strong').text('Permission Updated')
    //     $('.toast-body').text(`${label} set to ${text_value}`)
    //     $('.toast').toast('show')
    //   },
    //   error: (response) => {
    //     // attach an alert to the page with an error messages
    //     alert(`Failed to save permission: ${label}. Please refresh and try again`)
    //   }
    // })
  }
});


// submitChanges() {
//   $(this.submitActionSelector).trigger('blur')
//   if (this.isSaving) return
//   this.saving()
//   const {
//     tableContainerSelector,
//     tableObjectHeadingSelector,
//     tableInputSelector,
//   } = this.props
//   const rolePromises =
//     this.$tableContainer.data('objects')
//       .map((id, i) => {
//         const inputBaseQuery = `${tableInputSelector}[data-role=${id}] input`
//         const inputs = this.$tableContainer.find(`${inputBaseQuery}.dirty`)
//         if (inputs.length) {
//           inputs.add(`${tableContainerSelector} input[name=authenticity_token]`)
//           return $.ajax({
//             type: 'PATCH',
//             dataType: 'JSON',
//             url: `${this.patch_url}/${id}`,
//             data: this.$tableContainer.find(inputBaseQuery).serialize(),
//           })
//         } else {
//           return null
//         }
//       })
//   Promise.all(rolePromises)
//     .then(() => {
//       this.confirmSaved()
//     }).catch((error) => {
//       this.confirmSaved(error)
//     })
// }
