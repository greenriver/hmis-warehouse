import { Controller } from "@hotwired/stimulus"

// See app/assets/javascripts/stimulus_select.js for the original implementation, we probably want to port some comments if nothing else.
export default class extends Controller {
  static get targets() {
    return ['element', 'projectTypes', 'organizations', 'projects', 'optGroup', 'opt', 'selectAll'];
  }

  connect() {
    this.element['stimulusSelect'] = this; // allow access to this controller from other controllers
    this.enableFancySelect();
    this.watchForSelect2Opens();
    this.enableSelectGroup();
    this.setupDependentProjectList();
    this.fetchRemoteData();
  }

  setupDependentProjectList() {
    if (this.hasOrganizationsTarget) {
      $(this.organizationsTarget).on('select2:select', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.organizationsTarget).on('select2:unselect', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.organizationsTarget).on('select2:close', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.organizationsTarget).trigger('change');
    }
    if (this.hasProjectTypesTarget) {
      $(this.projectTypesTarget).on('select2:select', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.projectTypesTarget).on('select2:unselect', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.projectTypesTarget).on('select2:close', (e) => {
        let event = new Event('change', { bubbles: true }); // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.projectTypesTarget).trigger('change');
    }
  }

  // NOTE: this needs to work cross-controllers
  updateDependentProjectList() {
    let $project_controller = $('[data-stimulus-select-target*="projects"]').closest('[data-controller*="stimulus-select"]');
    let $organization_controller = $('[data-stimulus-select-target*="organizations"]').closest('[data-controller*="stimulus-select"]');
    let $project_types_controller = $('[data-stimulus-select-target*="projectTypes"]').closest('[data-controller*="stimulus-select"]');

    if ($project_controller.length > 0) {
      let project_stimulus = $project_controller[0].stimulusSelect;
      let $projectTarget = $(project_stimulus.projectsTarget);
      let selected_project_ids = $projectTarget.val();
      let url = $projectTarget.data('project-url');
      let selections = { selected_project_ids: selected_project_ids };
      if ($organization_controller.length > 0) {
        let organization_stimulus = $organization_controller[0].stimulusSelect;
        selections.organization_ids = $(organization_stimulus.organizationsTarget).val();
      }
      if ($project_types_controller.length > 0) {
        let project_types_stimulus = $project_types_controller[0].stimulusSelect;
        selections.project_types = $(project_types_stimulus.projectTypesTarget).val();
      }
      $.post(url, selections, (data) => {
        $projectTarget.html(data);
        $projectTarget.trigger('change');
      });
    }
  }

  fetchRemoteData() {
    let $select = $(this.elementTarget).filter('[data-collection-path]');
    if ($select.length) {
      const [url, data] = $select.data('collection-path').split('?');
      const original_placeholder = $select.attr('placeholder') || 'Please choose';
      const loading_placeholder = 'Loading...';
      $select.data('placeholder', loading_placeholder);
      if ($select.data('select2').selection.placeholder != undefined) {
        $select.data('select2').selection.placeholder.text = loading_placeholder;
      }
      $select.trigger('change');
      $.post(url, data, (data) => {
        $select.append(data);
        $select.data('placeholder', original_placeholder);
        if ($select.data('select2').selection.placeholder != undefined) {
          $select.data('select2').selection.placeholder.text = original_placeholder;
        }
        this._initToggleSelectAll();
        $select.trigger('change');
      });
    }
  }

  enableFancySelect() {
    let $select = $(this.elementTarget);
    let options = {
      dropdownParent: $(this.element)
    };

    if (this.elementTarget.classList.contains('select2-parenthetical-when-selected')) {
      options.templateSelection = (selected) => {
        if (!selected.id) { return selected.text; }
        const matched = selected.text.match(/\((.+?)\)/);
        if (matched && !matched.length == 2) {
          return selected.text;
        } else if (matched && matched.length) {
          return matched[1];
        } else {
          return selected.text;
        }
      };
    }

    if (this.elementTarget.classList.contains('select2-id-when-selected')) {
      options.templateSelection = (selected) => {
        if (!selected.id) { return selected.text; }
        return selected.id;
      };
    }

    if (this.elementTarget.hasAttribute('multiple')) {
      options.closeOnSelect = false;
    }

    let placeholder = $select.attr('placeholder');
    $select.attr('data-placeholder', placeholder);
    $select.select2(options);
    if (this.elementTarget.hasAttribute('multiple')) {
      this._initToggleSelectAll();
      $select.on('select2:unselecting', (e) => {
        $select.select2('open');
      });
    }
  }

  toggleAll() {
    if (this._anySourceOptionSelected()) {
      $(this.elementTarget).val([]);
    } else {
      let all_options = $(this.elementTarget).find('option').map((i, el) => { return el.value; });
      $(this.elementTarget).val(all_options);
    }
    $(this.elementTarget).trigger('change');
    $(this.elementTarget).trigger('select2:close');
  }

  watchForSelect2Opens() {
    let drop_down_class = '.select2-dropdown';
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;
    if (MutationObserver) {
      let observer = new MutationObserver((mutations) => {
        if ($(drop_down_class).length > 0) {
          $(drop_down_class).each((i, drop_down_span) => {
            $(drop_down_span).find('ul.select2-results__options--nested .select2-results__option:first-of-type').each((i, el) => {
              this.updateSelectAllState({ target: el });
            });
          });
        }
      });
      observer.observe(this.element, { attributes: false, childList: true, characterData: false, subtree: true });
    }
  }

  enableSelectGroup() {
    let opt_group_class = '.select2-results__group';
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver;
    if (MutationObserver) {
      let observer = new MutationObserver((mutations) => {
        if ($(opt_group_class).length > 0) {
          $(opt_group_class).each((i, strong) => {
            let $select_all = $(strong);
            $select_all
              .attr('data-stimulus-select-target', 'optGroup')
              .attr('data-action', 'click->stimulus-select#toggleChildren');
            let $parent = $select_all.next();
            $parent.find('li').each((i, el) => {
              $(el)
                .attr('data-stimulus-select-target', 'opt')
                .attr('data-action', 'click->stimulus-select#updateSelectAllState');
            });
          });
        }
      });
      observer.observe(this.element, { attributes: false, childList: true, characterData: false, subtree: true });
    }
  }

  updateSelectAllState(e) {
    let $parent = $(e.target).parent();
    let $select_all = $parent.prev();
    this._updateSelectAllClass($parent, $select_all);
  }

  toggleChildren(e) {
    let $select_all = $(e.target);
    let $parent = $select_all.next();
    let $original_select = $(this.elementTarget);
    this._updateSelectAllClass($parent, $select_all);
    let $options = $parent.find('li');
    let current_selection = $original_select.val();
    if ($select_all.hasClass('j-any-selected')) {
      let to_unselect = this._optionGroupOptionValues($options);
      $original_select.val(current_selection.filter(x => !to_unselect.includes(x)));
      $options.attr('aria-selected', false);
    } else {
      let to_select = this._optionGroupOptionValues($options);
      $original_select.val([...current_selection, ...to_select]);
    }
    $original_select.trigger('change');
  }

  _updateSelectAllClass($parent, $select_all) {
    if (this._anySelected($parent)) {
      $select_all.addClass('j-any-selected').removeClass('j-all-selected');
    } else {
      $select_all.removeClass('j-any-selected').removeClass('j-all-selected');
    }
  }

  _selectTwoDropDownId() {
    return $(this.elementTarget).data('select2').dropdown.$dropdown.attr('id');
  }

  _anySelected($parent) {
    return $parent.find('li[aria-selected="true"]').length > 0;
  }

  _anySourceOptionSelected() {
    return $(this.elementTarget).val().length > 0;
  }

  _originalSelectFrom($results) {
    let id = $results.closest('.select2-container').attr('id').replace('select2-', '').replace('-container', '');
    return $(`#${id}`);
  }

  _optionGroupOptionValues($options) {
    let ids = [];
    $options.each((i, el) => { ids.push(this._originalSelectFrom($(el)).find(`option:contains(${el.innerText})`)[0].value); });
    return ids;
  }

  _initToggleSelectAll() {
    let selectAllTarget = $(this.selectAllTarget);
    let selectTarget = $(this.elementTarget);

    if (selectAllTarget.length > 0) {
      selectAllTarget.removeClass('d-none');
      let hideSelectAllText = selectTarget.find('option:selected').length > 0;
      this._updateSelectAllText(hideSelectAllText);
      selectTarget.on('change', () => {
        let hideSelectAllText = selectTarget.find('option:selected').length > 0;
        this._updateSelectAllText(hideSelectAllText);
      });
    }
  }

  _selectAllText(hideSelectAllText) {
    let selectAllTarget = $(this.selectAllTarget);
    if (hideSelectAllText) {
      return selectAllTarget.data('deselect-text')
    } else {
      return selectAllTarget.data('select-text')
    }
  }

  _updateSelectAllText(hideSelectAllText) {
    let selectAllTarget = $(this.selectAllTarget);
    if (selectAllTarget.length > 0) {
      selectAllTarget.html(this._selectAllText(hideSelectAllText));
    }
  }
}
