window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('stimulus-select', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'projectTypes', 'organizations', 'projects']
  }

  initialize() {
    console.log('stimulus-select initializing')
    this.fetch_remote_data()

  }
  connect() {
    this.setupDependentProjectList()
  }

  sayHello() {
    console.log('sayHello fired')
  }

  setupDependentProjectList() {
    if (this.hasOrganizationsTarget) {
      $(this.organizationsTarget).trigger('change')
    }
    if (this.projectTypesTarget) {
      $(this.projectTypesTarget).trigger('change')
    }
  }

  updateDependentProjectList() {
    if (this.hasProjectsTarget) {
      let $projectTarget = $(this.projectsTarget)
      let selected_project_ids = $projectTarget.val()
      let url = $projectTarget.data('project-url')
      selections = { selected_project_ids: selected_project_ids }
      if (this.hasOrganizationsTarget) {
        selections.organization_ids = $(this.organizationsTarget).val()
      }
      if (this.projectTypesTarget) {
        selections.project_types = $(this.projectTypesTarget).val()
      }
      $.post(url, selections, (data) => {
        $projectTarget.html(data)
      })
    }
  }



  fetch_remote_data() {
    this.elementTargets.forEach((el) => {
      $select = $(el).filter('[data-collection-path]')
      if ($select.length) {
        // remote load
        console.log($select)
        // FIXME
        // [url, data] = $select.data('collection-path').split('?')
        // original_placeholder = $select.attr('placeholder') || 'Please choose'
        // loading_placeholder = 'Loading...'
        // $select.attr('placeholder', loading_placeholder)
        // $.post(url, data), (data) =>
        //   $select.append(data)
        //   $select.attr('placeholder', original_placeholder)
      }
    })
  }
})
