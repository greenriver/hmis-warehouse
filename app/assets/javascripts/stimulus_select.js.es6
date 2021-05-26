window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('stimulus-select', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'projectTypes', 'organizations', 'projects']
  }

  initialize() {
    console.log('stimulus-select initializing')
  }

  connect() {
    this.enableFancySelect()
    this.setupDependentProjectList()
    this.fetchRemoteData()
  }

  updateSelectAllStatus() {
    console.log('updateSelectAllStatus fired')
  }

  setupDependentProjectList() {
    console.log('setupDependentProjectList')
    $(this.organizationsTarget).on('select2:select', (e) => {
      let event = new Event('change', { bubbles: true }) // fire a native event
      e.target.dispatchEvent(event);
    });
    $(this.organizationsTarget).on('select2:clear', (e) => {
      let event = new Event('change', { bubbles: true }) // fire a native event
      e.target.dispatchEvent(event);
    });
    $(this.projectTypesTarget).on('select2:select', (e) => {
      let event = new Event('change', { bubbles: true }) // fire a native event
      e.target.dispatchEvent(event);
    });
    $(this.projectTypesTarget).on('select2:clear', (e) => {
      let event = new Event('change', { bubbles: true }) // fire a native event
      e.target.dispatchEvent(event);
    });
    if (this.hasOrganizationsTarget) {
      $(this.organizationsTarget).trigger('change')
    }
    if (this.hasProjectTypesTarget) {
      $(this.projectTypesTarget).trigger('change')
    }
  }

  updateDependentProjectList() {
    console.log('updateDependentProjectList')
    if (this.hasProjectsTarget) {
      let $projectTarget = $(this.projectsTarget)
      let selected_project_ids = $projectTarget.val()
      let url = $projectTarget.data('project-url')
      selections = { selected_project_ids: selected_project_ids }
      if (this.hasOrganizationsTarget) {
        selections.organization_ids = $(this.organizationsTarget).val()
      }
      if (this.hasProjectTypesTarget) {
        selections.project_types = $(this.projectTypesTarget).val()
      }
      $.post(url, selections, (data) => {
        $projectTarget.html(data)
      })
    }
  }

  fetchRemoteData() {
    this.elementTargets.forEach((el) => {
      let $select = $(el).filter('[data-collection-path]')
      if ($select.length) {
        const [url, data] = $select.data('collection-path').split('?')
        const original_placeholder = $select.attr('placeholder') || 'Please choose'
        const loading_placeholder = 'Loading...'
        $select.attr('placeholder', loading_placeholder)
        $.post(url, data, (data) => {
          $select.append(data)
          $select.attr('placeholder', original_placeholder)
        })
      }
    })
  }

  enableFancySelect() {
    $(this.elementTargets).select2()
  }
})
