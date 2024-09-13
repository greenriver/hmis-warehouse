window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('filter-projects', class extends Stimulus.Controller {
  static get values() {
    return {
      supportedProjectTypes: Array,
    }
  }

  static get targets() {
    return [
      'element',
      'header',
      'projects',
      'projectTypes',
      'dataSources',
      'organizations',
      'projectGroups',
      'funderIds',
      'cocCodes',
      'calculatedProjects',
      'missingItems',
      'submitButton',
    ]
  }

  initialize() {
    // console.log('filter-projects initializing')
  }

  connect() {
    this.element['filterProjects'] = this // allow access to this controller from other controllers
    this.prepNativeEvents()
    this.watchForRemoteLoads()
    this.update()
  }

  update() {
    let data = {
      project_ids: $(this.projectsTarget).val(),
      data_source_ids: $(this.dataSourcesTarget).val(),
      project_group_ids: $(this.projectGroupsTarget).val(),
      project_type_codes: $(this.projectTypesTarget).val(),
    }
    if (this.hasFunderIdsTarget) {
      const val = $(this.funderIdsTarget).val();
      if (val) data.funder_ids = Array.isArray(val) ? val : [val];
    }
    if (this.hasCocCodesTarget) {
      const val = $(this.cocCodesTarget).val();
      if (val) data.coc_codes = Array.isArray(val) ? val : [val];
    }
    if (this.hasOrganizationsTarget) {
      const val = $(this.organizationsTarget).val();
      if (val) data.organization_ids = Array.isArray(val) ? val : [val];
    }

    // Special parameter to limit the project list by supported project type IDs
    if (this.hasSupportedProjectTypesValue) {
      data.supported_project_types = this.supportedProjectTypesValue
    }

    $(this.calculatedProjectsTarget).html('<p class="well rollup-container"></p>')
    // Fetch the asynchronous nature of the query from the HTML, we'll set it to true for Development only
    const async = $(this.projectsTarget).data('async')

    $.ajax({
      // It is not ideal to call this synchronously as it sometimes hangs the browser temporarily,
      // but if these complete out of order, the project list gets funky.
      async: async,
      url: '/api/hud_filters',
      type: 'POST',
      data: data,
    }).done((ret) => {
      // console.debug('success')
      if (ret.includes('No Projects')) {
        this.addProjectDataWarning()
        $(this.submitButtonTarget).attr('disabled', 'disabled');
        this.resetMissingDataLink()
      }
      else {
        // we have some projects, so remove the warning
        this.removeProjectDataWarning()
        this.updateMissingDataLink(ret)
        if (this.checkMissingData(ret)) {
          // we have some data issues
          this.addMissingDataWarning()
          $(this.submitButtonTarget).attr('disabled', 'disabled');
        }
        else {
          // All good to proceed
          this.removeMissingDataWarning()
          $(this.submitButtonTarget).data('title', '').removeAttr('disabled');
        }
      }
      $(this.calculatedProjectsTarget).html(ret)
    }).fail((ret) => {
      console.error(['Failed to fetch project list', ret])
    })
  }

  resetMissingDataLink() {
    if (!this.hasMissingItemsTarget) {
      return
    }

    $(this.missingItemsTarget).attr('href', $(this.missingItemsTarget).data('defaultHref'));
  }

  updateMissingDataLink(html) {
    if (!this.hasMissingItemsTarget) {
      return
    }
    $(this.missingItemsTarget).attr('href', this.buildMissingDataLink(html));
  }

  checkMissingData(html) {
    if (! this.hasMissingItemsTarget) {
      return false
    }
    return $.ajax({ async: false, type: 'GET', url: this.buildMissingDataLink(html, true) }).done().responseJSON
  }

  buildMissingDataLink(html, json=false) {
    const base_missing_data_url = $(this.missingItemsTarget).data('defaultHref');
    const project_ids = $(html).find('li[value]').map(function () { return $(this).attr('value') }).get()
    if(json) {
      return base_missing_data_url + '.json?' + $.param({ filter: { project_ids: project_ids, coc_codes: $(this.cocCodesTarget).val() } })
    } else {
      return base_missing_data_url + '?' + $.param({ filter: { project_ids: project_ids, coc_codes: $(this.cocCodesTarget).val() } })
    }
  }

  addMissingDataWarning() {
    if (!this.hasMissingItemsTarget) {
      return
    }
    if ($('.jMissingDataWarning').length == 0) {
      $(this.submitButtonTarget).before('<p class="w-100 mb-4 alert alert-warning jMissingDataWarning">This report will not work unless the required project descriptor data is present, please see "Missing Data".</p>')
    }
  }

  removeMissingDataWarning() {
    $('.jMissingDataWarning').remove();
  }

  addProjectDataWarning() {
    if ($('.jProjectWarning').length == 0) {
      $(this.submitButtonTarget).before('<p class="w-100 mb-4 alert alert-warning jProjectWarning">This report will not work unless you have included at least one project above.</p>')
    }
  }

  removeProjectDataWarning() {
    $('.jProjectWarning').remove();
  }

  prepNativeEvents() {
    const targets = [
      this.projectsTarget,
      this.projectTypesTarget,
      this.dataSourcesTarget,
      this.projectGroupsTarget,
    ];
    if (this.hasFunderIdsTarget) targets.push(this.funderIdsTarget);
    if (this.hasCocCodesTarget) targets.push(this.cocCodesTarget);
    if (this.hasOrganizationsTarget) targets.push(this.organizationsTarget);

    targets.forEach(el => {
      $(el).on('select2:close', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
      $(el).trigger('change')
    })
  }

  // Projects can be loaded via ajax, make sure we update the list if that
  // takes longer than the rest of the page to happen
  watchForRemoteLoads() {
    const targets = [
      this.projectsTarget,
    ];
    targets.forEach(el => {
      $(el).on('change', (e) => {
        this.update()
      });
    });
  }
})
