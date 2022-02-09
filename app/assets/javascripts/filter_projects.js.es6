window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('filter-projects', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'header', 'projects', 'projectTypes', 'dataSources', 'projectGroups', 'calculatedProjects']
  }

  initialize() {
    // console.log('filter-projects initializing')
  }

  connect() {
    this.element['filterProjects'] = this // allow access to this controller from other controllers
    this.prepNativeEvents()
    this.update()
  }

  update() {
    let data = {
      project_ids: $(this.projectsTarget).val(),
      data_source_ids: $(this.dataSourcesTarget).val(),
      project_group_ids: $(this.projectGroupsTarget).val(),
      project_type_codes: $(this.projectTypesTarget).val(),
    }
    $(this.calculatedProjectsTarget).html('<p class="well rollup-container"></p>')
    $.ajax({
      // It is not ideal to call this synchronously as it sometimes hangs the browser temporarily,
      // but if these complete out of order, the project list gets funky.
      async: false,
      url: '/api/hud_filters',
      type: 'POST',
      data: data,
    }).done((ret) => {
      // console.debug('success')
      $(this.calculatedProjectsTarget).html(ret)
    }).fail((ret) => {
      console.error(['Failed to fetch project list', ret])
    })
  }

  prepNativeEvents() {
    [
      this.projectsTarget,
      this.projectTypesTarget,
      this.dataSourcesTarget,
      this.projectGroupsTarget,
    ].forEach(el => {
      $(el).on('select2:close', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
      $(el).trigger('change')
    })
  }
})
