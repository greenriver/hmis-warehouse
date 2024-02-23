window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('role-manager', class extends Stimulus.Controller {
  static get targets() {
    return ['permissionCategory', 'roleToggle', 'roleColumn', 'individualPermission', 'inputWrapper']
  }
  // This version of stimulus doesn't seem to support values
  // static values = {
  //   category: String,
  //   role: Integer
  // }


  connect() {
    this.element['roleManager'] = this // allow access to this controller from other controllers
    console.log('role manager connected', this.roleToggleTargets)
    this.path = $(this.inputWrapperTarget).data('roleManagerFormValue')
  }

  toggleSection(e) {
    let target_category = $(e.currentTarget).data('roleManagerCategoryValue')
    // find all of the sections with the same value and set their state to match
    this.permissionCategoryTargets.forEach((section) => {
      let section_category = $(section).data('roleManagerCategoryValue')
      if (section != e.currentTarget && section_category == target_category) {
        $(section).trigger('click')
      }
    });
  }

  toggleColumn(e) {
    let target = $(e.currentTarget)
    let target_role = target.data('roleManagerRoleValue')
    let input = $(target).find('input')

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

  save(e) {
    let target = $(e.currentTarget)
    let target_role_id = target.data('roleManagerRoleValue')
    let key = target.data('roleManagerPermissionValue')
    let checked = $(target).is(':checked')
    let value = checked ? '1' : '0'
    let data = { role: { } }
    data.role[key] = value
    console.log(target_role_id, key, checked, this.path, data)
    $.ajax({
      type: 'PATCH',
      dataType: 'JSON',
      url: `${this.path}/${target_role_id}`,
      data: data,
    })
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
