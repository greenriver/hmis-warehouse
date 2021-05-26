window.App.Form = window.App.Form || {}
window.App.StimulusApp = window.App.StimulusApp || {}

App.StimulusApp.register('stimulus-select', class extends Stimulus.Controller {
  static get targets() {
    return ['element', 'projectTypes', 'organizations', 'projects', 'optGroup', 'opt']
  }

  initialize() {
    console.log('stimulus-select initializing')
  }

  connect() {
    this.enableFancySelect()
    this.enableSelectGroup()
    this.setupDependentProjectList()
    this.fetchRemoteData()
  }

  updateSelectAllStatus() {
    console.log('updateSelectAllStatus fired')
  }

  setupDependentProjectList() {
    console.log('setupDependentProjectList')
    if (this.hasOrganizationsTarget) {
      $(this.organizationsTarget).on('select2:select', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.organizationsTarget).on('select2:unselect', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.organizationsTarget).trigger('change')
    }
    if (this.hasProjectTypesTarget) {
      $(this.projectTypesTarget).on('select2:select', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
      $(this.projectTypesTarget).on('select2:unselect', (e) => {
        let event = new Event('change', { bubbles: true }) // fire a native event
        e.target.dispatchEvent(event);
      });
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
    // maybe this should invoke a mutation observer looking for any of the targets being added to the page
    // then set them up as select2
    $(this.elementTargets).each((i, field) => {
      let options = {}
      if (field.hasAttribute('multiple')) {
        options.closeOnSelect = false
      }
      $(field).select2(options)
      // $(field).on('select2:open', this.updateSelectAllState(this))
    })
  }

  enableSelectGroup() {
    let opt_group_class = '.select2-results__group'
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if (MutationObserver) {
      let observer = new MutationObserver(function (mutations) {
        if ($(opt_group_class).length > 0) {
          $(opt_group_class).each((i, strong) => {

            let $select_all = $(strong)
            // Note these are added as attributes so stimulus will find them
            $select_all
              .attr('data-stimulus-select-target', 'optGroup')
              .attr('data-action', 'click->stimulus-select#toggleChildren')
            let $parent = $select_all.next()
            $parent.find('li').each((i, el) => {
              $(el)
                .attr('data-stimulus-select-target', 'opt')
                .attr('data-action', 'click->stimulus-select#updateSelectAllState')
            })
          })
        }
      });
      observer.observe(document, { attributes: false, childList: true, characterData: false, subtree: true });
    }
  }

  updateSelectAllState(e) {
    let $parent = $(e.target).parent()
    let $select_all = $parent.prev()

    this._updateSelectAllClass($parent, $select_all)
  }

  toggleChildren(e) {
    let $select_all = $(e.target)
    let $parent = $select_all.next()

    this._updateSelectAllClass($parent, $select_all)
    let $original_select = this._originalSelectFrom($select_all.closest('ul'))
    if ($select_all.hasClass('j-any-selected')) {
      let to_unselect = this._optionGroupOptionValues($parent.find('li[aria-selected=true]'))
      $original_select.find('option:selected').each((i, el) => {
        if (to_unselect.includes($(el).val())) {
          $(el).removeAttr('selected')
          console.log('un-selected: ', el)
        }
      })
      // $parent.find('li[aria-selected=true]').attr('')
    } else {
      let to_select = this._optionGroupOptionValues($parent.find('li[aria-selected=false]'))
      $original_select.find('option').each((i, el) => {
        if (to_select.includes($(el).val())) {
          $(el).attr('selected', 'selected')
          console.log('selected: ', el)
        }
      })
    }
    this._updateSelectAllClass($parent, $select_all)
    $original_select.trigger('change')
  }

  _updateSelectAllClass($parent, $select_all) {
    $select_all.removeClass('j-any-selected')
    if (this._anySelected($parent)) {
      $select_all.addClass('j-any-selected')
    }
  }

  _anySelected($parent) {
    return $parent.find('li[aria-selected=true]').length > 0
  }

  _originalSelectFrom($results) {
    let original_id = $results.attr('id').replace(/^select2-/, '').replace(/-results$/, '')
    return $(`[data-select2-id="${original_id}"]`)
  }

  _optionGroupOptionValues($options) {
    return $options.map((i, el) => {
      return el.id.split('-').pop()
    }).get()
  }
})
