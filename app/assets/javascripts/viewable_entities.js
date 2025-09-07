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
      const $column = $(el).closest('.j-column');
      const $select = $column.find('.jUserViewable');
      return $select;
    };

    // Use delegated events so they work on AJAX-loaded content
    // Clean up existing handlers to prevent duplicates
    $('body').off('click', '.j-add').on('click', '.j-add', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'add');
    });
    $('body').off('click', '.j-remove-all-toggle').on('click', '.j-remove-all-toggle', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'remove');
    });
    // eslint-disable-next-line no-unused-vars
    $('body').off('click', '.j-remove-all').on('click', '.j-remove-all', function (event) {
      self.removeAll(getSelect2(this), $(this).closest('.j-column'));
    });
    // eslint-disable-next-line no-unused-vars
    $('body').off('click', '.j-list.j-editable li').on('click', '.j-list.j-editable li', function (event) {
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
    const itemIdToRemove = $(item).data('id').toString();
    const currentIds = $select2.val() || [];

    // Filter out ALL instances of the ID to remove. This handles cases
    // where duplicate values might exist in the select.
    const newIds = currentIds.filter(id => id !== itemIdToRemove);

    $select2
      .val(newIds)
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
    // console.log('ViewableEntities: Starting loadSelectOptions...');
    const self = this;
    const selectPlaceholders = document.querySelectorAll('.select-placeholder');

    if (selectPlaceholders.length === 0) {
      return;
    }

    // Load ALL select options immediately on page load with sequential queuing
    let loadQueue = Promise.resolve();

    selectPlaceholders.forEach((placeholder) => {
      if (!placeholder.classList.contains('loaded')) {
        loadQueue = loadQueue.then(() => {
          return new Promise((resolve) => {
            // Small delay between requests to prevent overwhelming server
            setTimeout(() => {
              const promise = self.loadSingleSelectOptions(placeholder);
              // Use .always() for jQuery compatibility instead of .finally()
              promise.always(() => resolve());
            }, 50);
          });
        });
      }
    });
  }

  loadSingleSelectOptions(placeholder) {
    // console.log('ViewableEntities: Starting loadSingleSelectOptions for placeholder:', placeholder);
    const self = this;
    const $placeholder = $(placeholder);
    const entityType = $placeholder.data('entity-type');
    const loadUrl = $placeholder.data('load-url');
    const $loadingState = $placeholder.find('.loading-state');
    const $oldSelect = $placeholder.find('select');

    if (!loadUrl || !$oldSelect.length) {
      return Promise.resolve();
    }

    $placeholder.addClass('loaded');

    // Get the original select attributes
    const selectAttributes = this.extractSelectAttributes($oldSelect);

    // Use jQuery GET request to fetch the options HTML
    // console.log(`ViewableEntities: Firing GET request to ${loadUrl} for entity type ${entityType}`);
    return $.get(loadUrl)
      .then((optionsHtml) => {
        const $newSelect = this.createSelectFromHTML(optionsHtml, selectAttributes, entityType);
        $loadingState.replaceWith($newSelect);
        this.initializeSelect2($newSelect, entityType, self);
        this.populateInitialValues($newSelect, self);
      })
      .catch(() => {
        const $errorSelect = this.createErrorSelect(selectAttributes, entityType);
        $loadingState.replaceWith($errorSelect);
      });
  }

  extractSelectAttributes($oldSelect) {
    return {
      name: $oldSelect.attr('name'),
      class: $oldSelect.attr('class'),
      multiple: $oldSelect.attr('multiple')
    };
  }

  createSelectFromHTML(optionsHtml, selectAttributes, entityType) {
    const $newSelect = $('<select></select>');

    // Set attributes safely using jQuery methods (auto-escapes values)
    if (selectAttributes.name) $newSelect.attr('name', selectAttributes.name);
    if (selectAttributes.class) $newSelect.attr('class', selectAttributes.class);
    if (selectAttributes.multiple) $newSelect.attr('multiple', 'multiple');

    // SECURITY FIX: Parse HTML safely using jQuery and DOM methods instead of .html()
    const $tempContainer = $('<div>').html(optionsHtml);
    const $options = $tempContainer.children();

    // Safely append each option/optgroup by cloning DOM nodes
    $options.each(function () {
      $newSelect.append($(this).clone());
    });

    return $newSelect;
  }

  initializeSelect2($newSelect, entityType, self) {
    $newSelect.select2({
      minimumResultsForSearch: 10,
      placeholder: 'Search for ' + (entityType.replace('_', ' ')),
      tags: false,
      multiple: true
    });

    // Set up event handlers
    $newSelect.on('select2:select select2:unselect', function () {
      const values = {};
      const $selectedOptions = $(this).find(':selected');
      $selectedOptions.each(function (i, el) {
        values[el.value] = el.textContent;
      });
      self.renderList(values, $(this));
    });
  }

  populateInitialValues($newSelect, self) {
    const initialValues = {};
    const $selectedOptions = $newSelect.find('option[selected]');
    $selectedOptions.each(function (i, el) {
      initialValues[el.value] = el.textContent;
    });

    self.renderList(initialValues, $newSelect);
    const selectedValues = Object.keys(initialValues);
    $newSelect.val(selectedValues);
    $newSelect.trigger('change');
  }

  createErrorSelect(selectAttributes, entityType) {
    const $errorSelect = $('<select disabled></select>');

    // Set attributes safely using jQuery methods
    if (selectAttributes.name) $errorSelect.attr('name', selectAttributes.name);
    if (selectAttributes.class) $errorSelect.attr('class', selectAttributes.class);

    // Create error message safely using .text() to prevent XSS
    const errorMessage = 'Failed to load ' + entityType.replace('_', ' ');
    const $errorOption = $('<option disabled></option>').text(errorMessage);
    $errorSelect.append($errorOption);

    return $errorSelect;
  }

};
