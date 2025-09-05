// Ensure App namespace exists
window.App = window.App || {};

window.App.ViewableEntities = class {
  constructor() {
    console.log('ViewableEntities constructor called');
    console.log('Document ready state:', document.readyState);
    this.registerEvents();
    this.initSelect2();
    // Load select options via AJAX
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
    console.log('=== renderList called ===');
    console.log('Items to render:', items);
    console.log('List element:', $list[0]);

    const $container = $list.closest('.j-column');
    const $listContainer = $container.find('.j-list');
    const editable = $listContainer.hasClass('j-editable');
    const ids = Object.keys(items);
    const unlimitableIds = ($list.data('unlimitable') || []);

    console.log('Container:', $container[0]);
    console.log('List container:', $listContainer[0]);
    console.log('Is editable:', editable);
    console.log('Item IDs:', ids);

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

    console.log('Items markup:', itemsMarkup);
    console.log('No data message:', noDataMessage);
    console.log('Final HTML to set:', itemsMarkup || noDataMessage);
    console.log('List container before update:', $listContainer.html());

    $listContainer.html(itemsMarkup || noDataMessage);

    console.log('List container after update:', $listContainer.html());
    console.log('=== renderList finished ===');

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
    console.log('=== loadSelectOptions called ===');
    const self = this;
    const selectPlaceholders = document.querySelectorAll('.select-placeholder');
    console.log('Found select placeholders:', selectPlaceholders.length);

    // Log details about each placeholder
    selectPlaceholders.forEach((placeholder, index) => {
      console.log(`Select placeholder ${index}:`, {
        entityType: placeholder.dataset.entityType,
        userId: placeholder.dataset.userId,
        base: placeholder.dataset.base,
        loadUrl: placeholder.dataset.loadUrl,
        element: placeholder
      });
    });

    // If no placeholders found, user might be using ACLs instead of legacy permissions
    if (selectPlaceholders.length === 0) {
      console.log('No select placeholders found - user may be using ACL permissions');
      return;
    }

    // Load select options when their tab becomes visible or when Add button is clicked
    const handleTabShown = (event) => {
      console.log('=== Tab shown event triggered ===');
      console.log('Event target:', event.target);
      console.log('Tab href:', event.target.getAttribute('href'));
      const tabPane = document.querySelector(event.target.getAttribute('href'));
      if (!tabPane) {
        console.log('No tab pane found for:', event.target.getAttribute('href'));
        return;
      }

      console.log('Tab pane found:', tabPane);
      const placeholdersInTab = tabPane.querySelectorAll('.select-placeholder:not(.loaded)');
      console.log('Select placeholders in tab:', placeholdersInTab.length);

      if (placeholdersInTab.length > 0) {
        console.log('Loading select options in tab...');
        placeholdersInTab.forEach(placeholder => {
          console.log('Loading select options for:', placeholder.dataset.entityType);
          self.loadSingleSelectOptions(placeholder);
        });
      } else {
        console.log('No unloaded select placeholders found in this tab');
      }
    };

    // Load select options when Add button is clicked
    const handleAddClick = (event) => {
      console.log('=== Add button clicked ===');
      const column = event.target.closest('.j-column');
      if (!column) return;

      const placeholder = column.querySelector('.select-placeholder:not(.loaded)');
      if (placeholder) {
        console.log('Loading select options on Add click:', placeholder.dataset.entityType);
        self.loadSingleSelectOptions(placeholder);
      }
    };

    // Add event listeners to tab links
    const tabLinks = document.querySelectorAll('[data-bs-toggle="tab"]');
    console.log('Found tab links:', tabLinks.length);
    tabLinks.forEach((tab, index) => {
      console.log(`Tab ${index}:`, tab.getAttribute('href'));

      // Try multiple event names for different Bootstrap versions
      tab.addEventListener('shown.bs.tab', handleTabShown);
      tab.addEventListener('shown', handleTabShown);  // Bootstrap 3 fallback

      // Also add click handler as fallback
      tab.addEventListener('click', (event) => {
        console.log('Tab clicked:', event.target.getAttribute('href'));
        // Small delay to ensure tab content is visible
        setTimeout(() => handleTabShown(event), 100);
      });
    });

    // Add event listeners to Add buttons using delegation
    $('body').on('click', '.j-add', handleAddClick);

    // Load select options in the active tab immediately on page load
    const activeTabPane = document.querySelector('.tab-pane.active');
    console.log('Active tab pane:', activeTabPane);
    if (activeTabPane) {
      const activePlaceholders = activeTabPane.querySelectorAll('.select-placeholder:not(.loaded)');
      console.log('Active select placeholders to load immediately:', activePlaceholders.length);
      activePlaceholders.forEach((placeholder, index) => {
        console.log(`Loading active select placeholder ${index} immediately:`, placeholder.dataset.entityType);
        self.loadSingleSelectOptions(placeholder);
      });
    } else {
      console.log('No active tab pane found');
    }

    // Also load ALL select options immediately for better UX (optional - can remove if too many requests)
    console.log('Loading ALL select options immediately for best UX');
    selectPlaceholders.forEach((placeholder, index) => {
      if (!placeholder.classList.contains('loaded')) {
        console.log(`Pre-loading select placeholder ${index}:`, placeholder.dataset.entityType);
        // Small delay to stagger requests
        setTimeout(() => {
          self.loadSingleSelectOptions(placeholder);
        }, index * 50); // 50ms delay between each request
      }
    });
    console.log('=== loadSelectOptions finished ===');
  }

  loadSingleSelectOptions(placeholder) {
    console.log('=== loadSingleSelectOptions called ===');
    const self = this;
    const $placeholder = $(placeholder);
    const entityType = $placeholder.data('entity-type');
    const loadUrl = $placeholder.data('load-url');
    const $select = $placeholder.find('select');

    console.log('Loading select options:', {
      entityType,
      loadUrl,
      placeholder,
      select: $select[0]
    });

    if (!loadUrl) {
      console.error('No load URL found for select placeholder:', entityType);
      return;
    }

    if (!$select.length) {
      console.error('No select element found in placeholder:', entityType);
      return;
    }

    $placeholder.addClass('loaded');
    console.log('Added "loaded" class to select placeholder');
    console.log('Fetching options from URL:', loadUrl);

    const startTime = performance.now();

    // Use jQuery GET request to fetch the options HTML
    $.get(loadUrl)
      .done((optionsHtml) => {
        const totalTime = performance.now() - startTime;
        console.log(`Options HTML received in ${totalTime.toFixed(2)}ms`);
        console.log('Options HTML length:', optionsHtml.length);
        console.log('Options HTML preview:', optionsHtml.substring(0, 200) + '...');

        console.log('Replacing select options');
        // Clear existing options and add new ones
        $select.empty().html(optionsHtml);

        // Enable the select
        $select.prop('disabled', false);

        console.log('Re-initializing Select2 for loaded select');
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
        console.log('=== Processing selected options after AJAX ===');
        console.log('Found selected options:', $selectedOptions.length);
        console.log('Selected options elements:', $selectedOptions.toArray());
        console.log('Initial selected values:', initialValues);
        console.log('About to call renderList with:', initialValues);

        // Always call renderList to either show selected items or clear "No items selected" message
        self.renderList(initialValues, $select);

        // Set the select2 value to match the selected options
        const selectedValues = Object.keys(initialValues);
        console.log('Setting Select2 values to:', selectedValues);
        $select.val(selectedValues);

        // Trigger change event to update Select2 display
        $select.trigger('change');

        console.log('Successfully loaded select options for:', entityType);
      })
      .fail((xhr, status, error) => {
        console.error('Error loading select options:', error);
        console.error('Error details:', {
          entityType,
          loadUrl,
          status: xhr.status,
          statusText: xhr.statusText,
          error: error
        });

        $select.empty().html(`
          <option disabled>Failed to load ${entityType.replace('_', ' ')}</option>
        `);
      });
  }

  // Keep the old method for backward compatibility (if needed)
  loadSingleEntityColumn(placeholder) {
    console.log('=== loadSingleEntityColumn called (deprecated) ===');
    const self = this;
    const $placeholder = $(placeholder);
    const entityType = $placeholder.data('entity-type');
    const loadUrl = $placeholder.data('load-url');

    console.log('Loading entity column:', {
      entityType,
      loadUrl,
      placeholder
    });

    if (!loadUrl) {
      console.error('No load URL found for placeholder:', entityType);
      return;
    }

    $placeholder.addClass('loaded');
    console.log('Added "loaded" class to placeholder');
    console.log('Fetching URL:', loadUrl);

    const startTime = performance.now();

    // Use jQuery GET request like in stimulus_select_controller.js
    $.get(loadUrl)
      .done((html) => {
        const totalTime = performance.now() - startTime;
        console.log(`HTML received in ${totalTime.toFixed(2)}ms`);
        console.log('HTML length:', html.length);
        console.log('HTML preview:', html.substring(0, 200) + '...');

        console.log('Replacing placeholder with loaded content');
        $placeholder.replaceWith(html);

        console.log('Re-initializing Select2 and tooltips');
        // Re-initialize Select2 for the newly loaded content
        self.initSelect2();
        // Re-initialize tooltips
        document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new window.bootstrap.Tooltip(el));

        console.log('Successfully loaded entity column for:', entityType);
      })
      .fail((xhr, status, error) => {
        console.error('Error loading entity column:', error);
        console.error('Error details:', {
          entityType,
          loadUrl,
          status: xhr.status,
          statusText: xhr.statusText,
          error: error
        });

        $placeholder.html(`
          <div class="alert alert-warning text-center p-4">
            <i class="icon-warning"></i>
            <p class="mt-2">Failed to load ${entityType.replace('_', ' ')}. Please refresh the page.</p>
            <small class="text-muted">Error: ${xhr.status} ${xhr.statusText}</small>
          </div>
        `);
      });
  }
};
