window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('role-manager', class extends Stimulus.Controller {
  static get targets() {
    return ['permissionCategory', 'roleToggle', 'roleColumn']
  }
  // This version of stimulus doesn't seem to support values
  // static values = {
  //   category: String,
  //   role: Integer
  // }


  connect() {
    this.element['roleManager'] = this // allow access to this controller from other controllers
    console.log('role manager connected', this.roleToggleTargets)
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
});
