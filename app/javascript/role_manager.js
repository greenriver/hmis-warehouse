window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('role-manager', class extends Stimulus.Controller {
  static get targets() {
    return ['permissionCategory']
  }
  // This version of stimulus doesn't seem to support values
  // static values = {
  //   category: String
  // }


  initialize() {
    console.log('role manager initializing')
  }

  connect() {
    this.element['roleManager'] = this // allow access to this controller from other controllers
    console.log('role manager connected', this.permissionCategoryTargets)
  }

  toggleSection(e) {
    console.log(e.currentTarget)
    let target_category = $(e.currentTarget).data('roleManagerCategoryValue')
    // find all of the sections with the same value and set their state to match
    this.permissionCategoryTargets.forEach((section) => {
      let section_category = $(section).data('roleManagerCategoryValue')
      if (section != e.currentTarget && section_category == target_category) {
        console.log('opening', section, section_category)
        $(section).trigger('click')
      }
    });
  }
});
