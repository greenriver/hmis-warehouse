// Ensure App namespace exists
window.App = window.App || {};

window.App.ViewableEntities = class {
  constructor() {
    this.registerEvents();
    this.initSelect2();
    this.loadSelectOptions();
    document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new window.bootstrap.Tooltip(el));
  }

  registerEvents() {
    const self = this;
    const showHideEl = (event, relatedElement) => {
      event.preventDefault();
      const $container = $(event.currentTarget).closest('.j-column');
      const $element = $container.find('.j-column-actions-' + relatedElement);
      const $content = $container.find('.j-column-content');
      $element.siblings().addClass('hide');
      $element.toggleClass('hide');
      $content.toggleClass('active');
      let select2Action = 'open';
      let contentAction = 'addClass';
      if ($element.hasClass('hide')) {
        select2Action = 'close';
        contentAction = 'removeClass';
      }
      $content[contentAction]('inactive');
      $element.find('.jUserViewable').select2(select2Action);
    };

    const getSelect2 = (el) => {
      return $(el).closest('.j-column').find('.jUserViewable');
    };

    // Use delegated events so they work on AJAX-loaded content
    $('body').on('click', '.j-add', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'add');
    });
    $('body').on('click', '.j-remove-all-toggle', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'remove');
    });
    // eslint-disable-next-line no-unused-vars
    $('body').on('click', '.j-remove-all', function (event) {
      self.removeAll(getSelect2(this), $(this).closest('.j-column'));
    });
    // eslint-disable-next-line no-unused-vars
    $('body').on('click', '.j-list.j-editable li', function (event) {
      self.removeItem(this, getSelect2(this));
    });
  }

  renderList(items, $list) {
    const $container = $list.closest('.j-column');
    const $listContainer = $container.find('.j-list');
    const editable = $listContainer.hasClass('j-editable');
    const ids = Object.keys(items);
    const unlimitableIds = ($list.data('unlimitable') || []);

    const itemValues = [];
    for (const i in items) {
      // eslint-disable-next-line no-prototype-builtins
      if (items.hasOwnProperty(i)) {
        itemValues.push(items[i]);
      }
    }
    const itemsMarkup = itemValues.map((item, i) => {
      let unlimitable = '';
      if (unlimitableIds.includes(parseInt(ids[i]))) {
        unlimitable = '<span data-bs-toggle="tooltip" title="This report is not limitable"><i class="ml-2 mr-2 icon-notification"></i></span>';
      }
      let icon_span = '<span/>';
      if (editable) {
        icon_span = '<span> <i class=\'icon-cross\'></i></span>';
      }
      return `
        <li class='c-columns__column-list-item' data-id=${ids[i]}>
          <span>${item}</span>
          ${unlimitable}
          ${icon_span}
        </li>
      `;
    }).join('');
    const hasAssociated = $listContainer.siblings().first().children().length;
    let noDataMessage = '<li class="c-columns__column-list-item--read-only font-italic">No ' + this.getEntityName($container) + ' selected.</li>';
    if (hasAssociated) {
      noDataMessage = '';
    }

    $listContainer.html(itemsMarkup || noDataMessage);
    $listContainer.find('[data-bs-toggle="tooltip"]').each((_, e) => new window.bootstrap.Tooltip(e));
  }

  getEntityName($column) {
    return $column.data('title') || '';
  }

  removeAll($select2, $container) {
    $select2
      .val('')
      .trigger('change');
    $container.find('.j-list').html('');
    $container.find('.j-column-actions-remove').addClass('hide');
  }

  removeItem(item, $select2) {
    const currentIds = $select2.val();
    const index = currentIds.indexOf($(item).data('id').toString());
    if (index > -1) {
      currentIds.splice(index, 1);
    }
    $select2
      .val(currentIds)
      .trigger('change');
    $(item).remove();
  }

  initSelect2() {
    const self = this;

    // Use delegated events for clear select buttons
    $('body').off('click', '.jClearSelect').on('click', '.jClearSelect', function (event) {
      event.preventDefault();
      var select_class = $(event.currentTarget).data('input-class');
      $('select.' + select_class).find('option:selected').prop('selected', false);
      return $('select.' + select_class).trigger('change');
    });

    const values = function ($this, includeSelected = false) {
      let query = 'option[selected]';
      if (includeSelected) {
        query = ':selected';
      }
      const $selectedOptions = $this.find(query);
      // eslint-disable-next-line no-unused-vars
      const values = $this.val();
      const selected = {};
      $selectedOptions.each(function (i, el) {
        selected[el.value] = el.textContent;
      });
      self.renderList(selected, $this);
      return selected;
    };

    const init = ($this) => {
      return $(function () {
        // Skip if already initialized
        if ($this.hasClass('select2-hidden-accessible')) {
          return;
        }

        // Check if this is a lazy-loaded select (disabled means it's waiting for AJAX)
        const isLazyLoaded = $this.prop('disabled');

        $this.select2({
          minimumResultsForSearch: 10,
          placeholder: 'Search for ' + $this.attr('placeholder'),
          tags: false,
          multiple: true
        });

        // Only call renderList for non-lazy selects, lazy ones will be handled after AJAX
        if (!isLazyLoaded) {
          $this.val(Object.keys(values($this))).trigger('change');
        }
      });
    };

    // Initialize Select2 on all jUserViewable elements (including newly loaded ones)
    $('.jUserViewable').each(function () {
      const $this = $(this);

      // Remove existing event handlers to avoid duplicates
      $this.off('select2:select select2:unselect');

      // Add event handlers
      $this.on('select2:select select2:unselect', function () {
        self.renderList(values($(this), true), $(this));
      });

      init($this);
    });
  }

  loadSelectOptions() {
    const self = this;
    const selectPlaceholders = document.querySelectorAll('.select-placeholder');

    if (selectPlaceholders.length === 0) {
      return;
    }

    // Load select options when their tab becomes visible or when Add button is clicked
    const handleTabShown = (event) => {
      const tabPane = document.querySelector(event.target.getAttribute('href'));
      if (!tabPane) return;

      const placeholdersInTab = tabPane.querySelectorAll('.select-placeholder:not(.loaded)');
      if (placeholdersInTab.length > 0) {
        placeholdersInTab.forEach(placeholder => {
          self.loadSingleSelectOptions(placeholder);
        });
      }
    };

    // Load select options when Add button is clicked
    const handleAddClick = (event) => {
      const column = event.target.closest('.j-column');
      if (!column) return;

      const placeholder = column.querySelector('.select-placeholder:not(.loaded)');
      if (placeholder) {
        self.loadSingleSelectOptions(placeholder);
      }
    };

    // Add event listeners to tab links
    const tabLinks = document.querySelectorAll('[data-bs-toggle="tab"]');
    tabLinks.forEach((tab) => {
      // Try multiple event names for different Bootstrap versions
      tab.addEventListener('shown.bs.tab', handleTabShown);
      tab.addEventListener('shown', handleTabShown);  // Bootstrap 3 fallback

      // Also add click handler as fallback
      tab.addEventListener('click', (event) => {
        // Small delay to ensure tab content is visible
        setTimeout(() => handleTabShown(event), 100);
      });
    });

    // Add event listeners to Add buttons using delegation
    $('body').on('click', '.j-add', handleAddClick);

    // Load select options in the active tab immediately on page load
    const activeTabPane = document.querySelector('.tab-pane.active');
    if (activeTabPane) {
      const activePlaceholders = activeTabPane.querySelectorAll('.select-placeholder:not(.loaded)');
      activePlaceholders.forEach((placeholder) => {
        self.loadSingleSelectOptions(placeholder);
      });
    }

    // Also load ALL select options immediately for better UX
    selectPlaceholders.forEach((placeholder, index) => {
      if (!placeholder.classList.contains('loaded')) {
        // Small delay to stagger requests
        setTimeout(() => {
          self.loadSingleSelectOptions(placeholder);
        }, index * 50); // 50ms delay between each request
      }
    });
  }

  loadSingleSelectOptions(placeholder) {
    const self = this;
    const $placeholder = $(placeholder);
    const entityType = $placeholder.data('entity-type');
    const loadUrl = $placeholder.data('load-url');
    const $select = $placeholder.find('select');

    if (!loadUrl || !$select.length) {
      return;
    }

    $placeholder.addClass('loaded');

    // Use jQuery GET request to fetch the options HTML
    $.get(loadUrl)
      .done((optionsHtml) => {
        // Clear existing options and add new ones
        $select.empty().html(optionsHtml);

        // Enable the select
        $select.prop('disabled', false);

        // Re-initialize Select2 for this specific select (if not already initialized)
        if (!$select.hasClass('select2-hidden-accessible')) {
          $select.select2({
            minimumResultsForSearch: 10,
            placeholder: 'Search for ' + $select.attr('placeholder'),
            tags: false,
            multiple: true
          });

          // Set up event handlers
          $select.on('select2:select select2:unselect', function () {
            const values = {};
            const $selectedOptions = $(this).find(':selected');
            $selectedOptions.each(function (i, el) {
              values[el.value] = el.textContent;
            });
            self.renderList(values, $(this));
          });
        }

        // ALWAYS populate the initial list of selected items (regardless of Select2 state)
        const initialValues = {};
        const $selectedOptions = $select.find('option[selected]');
        $selectedOptions.each(function (i, el) {
          initialValues[el.value] = el.textContent;
        });

        // Always call renderList to either show selected items or clear "No items selected" message
        self.renderList(initialValues, $select);

        // Set the select2 value to match the selected options
        const selectedValues = Object.keys(initialValues);
        $select.val(selectedValues);

        // Trigger change event to update Select2 display
        $select.trigger('change');
      })
      .fail((xhr, status, error) => {
        $select.empty().html(`
          <option disabled>Failed to load ${entityType.replace('_', ' ')}</option>
        `);
      });
  }

};
