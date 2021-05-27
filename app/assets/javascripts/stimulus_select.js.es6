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
    this.watchForSelect2Opens()
    this.enableSelectGroup()
    this.setupDependentProjectList()
    this.fetchRemoteData()
  }

  setupDependentProjectList() {
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
    // $(this.elementTargets).each((i, field) => {
    //   let options = {}
    //   if (field.hasAttribute('multiple')) {
    //     options.closeOnSelect = false
    //   }
    //   $(field).select2(options)
    // })

    let select_target = '[data-stimulus-select-target*="element"]'
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if (MutationObserver) {
      let observer = new MutationObserver((mutations) => {
        console.log($(select_target).length)
        if ($(select_target).length > 0) {
          console.log($(select_target).length)
          $(select_target).each((i, field) => {
            console.log(field)
            // let options = {}
            // if (field.hasAttribute('multiple')) {
            //   options.closeOnSelect = false
            // }
            // $(field).select2(options)
          })
        }
      });
      observer.observe(document, { attributes: false, childList: true, characterData: false, subtree: true });
    }
  }

  watchForSelect2Opens() {
    let drop_down_class = '.select2-dropdown'
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if (MutationObserver) {
      let observer = new MutationObserver((mutations) => {
        if ($(drop_down_class).length > 0) {
          $(drop_down_class).each((i, drop_down_span) => {
            $(drop_down_span).find('ul.select2-results__options--nested .select2-results__option:first-of-type').each((i, el) => {
              // trigger an update on the first option in each group to keep the select all/none text in sync
              this.updateSelectAllState({target: el})
            })
          })
        }
      });
      observer.observe(document, { attributes: false, childList: true, characterData: false, subtree: true });
    }
  }

  enableSelectGroup() {
    let opt_group_class = '.select2-results__group'
    const MutationObserver = window.MutationObserver || window.WebKitMutationObserver || window.MozMutationObserver
    if (MutationObserver) {
      let observer = new MutationObserver((mutations) => {
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
    let $original_select = this._originalSelectFrom($select_all.closest('ul'))

    // set class on select_alls so we can determine what to do based on what's currently selected
    this._updateSelectAllClass($parent, $select_all)

    if ($select_all.hasClass('j-any-selected')) {
      let $options = $parent.find('li[aria-selected=true]')
      let to_unselect = this._optionGroupOptionValues($options)
      $original_select.find('option:selected').each((i, el) => {
        if (to_unselect.includes($(el).val())) {
          $(el).removeAttr('selected')
        }
      })
      $options.attr('aria-selected', false)
    } else {
      let $options = $parent.find('li[aria-selected=false]')
      let to_select = this._optionGroupOptionValues($options)
      $original_select.find('option').each((i, el) => {
        if (to_select.includes($(el).val())) {
          $(el).attr('selected', 'selected')
        }
      })
      $options.attr('aria-selected', true)
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
