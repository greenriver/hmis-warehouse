import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get values() {
    return {
      supportedProjectTypes: Array,
    };
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
      'funderOthers',
      'cocCodes',
      'calculatedProjects',
      'missingItems',
      'submitButton',
    ];
  }

  connect() {
    this.element['filterProjects'] = this;
    this.prepNativeEvents();
    this.watchForRemoteLoads();
    this.update();
  }

  update() {
    let data = this.formData();
    $(this.calculatedProjectsTarget).html('<p class="well rollup-container"></p>');
    const async = $(this.projectsTarget).data('async');
    $.ajax({
      async: async,
      url: '/api/hud_filters',
      type: 'POST',
      data: data,
    }).done((ret) => {
      if (ret.includes('No Projects')) {
        this.addProjectDataWarning();
        $(this.submitButtonTarget).attr('disabled', 'disabled');
      }
      else {
        this.removeProjectDataWarning();
        if (this.checkMissingData()) {
          this.addMissingDataWarning();
          $(this.submitButtonTarget).attr('disabled', 'disabled');
        }
        else {
          this.removeMissingDataWarning();
          $(this.submitButtonTarget).data('title', '').removeAttr('disabled');
        }
      }
      $(this.calculatedProjectsTarget).html(ret);
    }).fail((ret) => {
      console.error(['Failed to fetch project list', ret]);
    });
  }

  formData() {
    let data = {
      project_ids: $(this.projectsTarget).val(),
      data_source_ids: $(this.dataSourcesTarget).val(),
      project_group_ids: $(this.projectGroupsTarget).val(),
      project_type_codes: $(this.projectTypesTarget).val(),
    };
    if (this.hasFunderIdsTarget) {
      const val = $(this.funderIdsTarget).val();
      if (val) data.funder_ids = Array.isArray(val) ? val : [val];
    }
    if (this.hasFunderOthersTarget) {
      const val = $(this.funderOthersTarget).val();
      if (val) data.funder_others = Array.isArray(val) ? val : [val];
    }
    if (this.hasCocCodesTarget) {
      const val = $(this.cocCodesTarget).val();
      if (val) data.coc_codes = Array.isArray(val) ? val : [val];
    }
    if (this.hasOrganizationsTarget) {
      const val = $(this.organizationsTarget).val();
      if (val) data.organization_ids = Array.isArray(val) ? val : [val];
    }
    if (this.hasSupportedProjectTypesValue) {
      data.supported_project_types = this.supportedProjectTypesValue;
    }
    return data;
  }

  rawFormFiltersInput() {
    let inputs = {};
    $(this.element).find(':input').each((i, el) => {
      if (el.name.startsWith('filter[')) {
        const nameParts = el.name.replaceAll('][]', '').replaceAll(']', '').split('[');
        const input = nameParts.reduceRight((nestedObj, key) => ({ [key]: nestedObj }), $(el).val());
        inputs = $.extend(true, {}, inputs, input);
      }
    });
    return inputs;
  }

  checkMissingData() {
    if (!this.hasMissingItemsTarget) {
      return false;
    }
    const form_data = this.rawFormFiltersInput();
    return $.ajax({
      async: false, type: 'POST', url: $(this.missingItemsTarget).attr('formaction') + '.json', data: JSON.stringify(form_data), contentType: 'application/json'
    }).done().responseJSON;
  }

  addMissingDataWarning() {
    if (!this.hasMissingItemsTarget) {
      return;
    }
    if ($('.jMissingDataWarning').length == 0) {
      $(this.submitButtonTarget).before('<p class="w-100 mb-4 alert alert-warning jMissingDataWarning">This report will not work unless the required project descriptor data is present, please see "Missing Data".</p>');
    }
  }

  removeMissingDataWarning() {
    $('.jMissingDataWarning').remove();
  }

  addProjectDataWarning() {
    if ($('.jProjectWarning').length == 0) {
      $(this.submitButtonTarget).before('<p class="w-100 mb-4 alert alert-warning jProjectWarning">This report will not work unless you have included at least one project above.</p>');
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
    if (this.hasFunderOthersTarget) targets.push(this.funderOthersTarget);
    if (this.hasCocCodesTarget) targets.push(this.cocCodesTarget);
    if (this.hasOrganizationsTarget) targets.push(this.organizationsTarget);

    targets.forEach(el => {
      $(el).on('select2:close', (e) => {
        let event = new Event('change', { bubbles: true });
        e.target.dispatchEvent(event);
      });
      $(el).trigger('change');
    });

    if (this.hasMissingItemsTarget) {
      $(this.submitButtonTarget).removeAttr('data-disable-with');
      $(this.missingItemsTarget).removeAttr('data-disable-with');
    }
  }

  watchForRemoteLoads() {
    const targets = [
      this.projectsTarget,
    ];
    targets.forEach(el => {
      $(el).on('change', (e) => {
        this.update();
      });
    });
  }
}
