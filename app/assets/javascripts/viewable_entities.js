// Ensure App namespace exists
window.App = window.App || {};

window.App.ViewableEntities = class {
  constructor() {
    console.log('ViewableEntities constructor called');
    console.log('Document ready state:', document.readyState);
    this.registerEvents();
    this.initSelect2();
    // Since we're now called after DOMContentLoaded in the template, we can load immediately
    this.loadEntityColumns();
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

    $('.j-add').on('click', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'add');
    });
    $('.j-remove-all-toggle').on('click', (event) => {
      // eslint-disable-next-line no-unused-vars
      const elements = showHideEl(event, 'remove');
    });
    // eslint-disable-next-line no-unused-vars
    $('.j-remove-all').on('click', function (event) {
      self.removeAll(getSelect2(this), $(this).closest('.j-column'));
    });
    // eslint-disable-next-line no-unused-vars
    $('.j-list.j-editable').on('click', 'li', function (event) {
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
    $('.jClearSelect').on('click', function (event) {
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
        $this.select2({
          minimumResultsForSearch: 10,
          placeholder: 'Search for ' + $this.attr('placeholder'),
          tags: false,
          multiple: true
        });
        $this.val(Object.keys(values($this))).trigger('change');
      });
    };

    $('.jUserViewable').each(function () {
      const $this = $(this);
      $this.on('select2:select select2:unselect', function () {
        self.renderList(values($(this), true), $(this));
      });
      init($this);
    });
  }

  loadEntityColumns() {
    console.log('=== loadEntityColumns called ===');
    const self = this;
    const placeholders = document.querySelectorAll('.entity-column-placeholder');
    console.log('Found placeholders:', placeholders.length);

    // Log details about each placeholder
    placeholders.forEach((placeholder, index) => {
      console.log(`Placeholder ${index}:`, {
        entityType: placeholder.dataset.entityType,
        userId: placeholder.dataset.userId,
        base: placeholder.dataset.base,
        element: placeholder
      });
    });

    // If no placeholders found, user might be using ACLs instead of legacy permissions
    if (placeholders.length === 0) {
      console.log('No entity column placeholders found - user may be using ACL permissions');
      return;
    }

    // Load entity columns when their tab becomes visible
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
      const placeholdersInTab = tabPane.querySelectorAll('.entity-column-placeholder:not(.loaded)');
      console.log('Placeholders in tab:', placeholdersInTab.length);

      if (placeholdersInTab.length > 0) {
        console.log('Loading placeholders in tab...');
        placeholdersInTab.forEach(placeholder => {
          console.log('Loading placeholder in tab:', placeholder.dataset.entityType);
          self.loadSingleEntityColumn(placeholder);
        });
      } else {
        console.log('No unloaded placeholders found in this tab');
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

    // Load entities in the active tab immediately
    const activeTabPane = document.querySelector('.tab-pane.active');
    console.log('Active tab pane:', activeTabPane);
    if (activeTabPane) {
      const activePlaceholders = activeTabPane.querySelectorAll('.entity-column-placeholder:not(.loaded)');
      console.log('Active placeholders to load:', activePlaceholders.length);
      activePlaceholders.forEach((placeholder, index) => {
        console.log(`Loading active placeholder ${index}:`, placeholder.dataset.entityType);
        self.loadSingleEntityColumn(placeholder);
      });
    } else {
      console.log('No active tab pane found');
    }
    console.log('=== loadEntityColumns finished ===');
  }

  loadSingleEntityColumn(placeholder) {
    console.log('=== loadSingleEntityColumn called ===');
    const self = this;
    const entityType = placeholder.dataset.entityType;
    const userId = placeholder.dataset.userId;
    const base = placeholder.dataset.base || 'user';

    console.log('Loading entity column:', {
      entityType,
      userId,
      base,
      placeholder
    });

    // Check for CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]');
    if (!csrfToken) {
      console.error('No CSRF token found in page');
    } else {
      console.log('CSRF token found:', csrfToken.getAttribute('content').substring(0, 10) + '...');
    }

    placeholder.classList.add('loaded');
    console.log('Added "loaded" class to placeholder');

    const url = `/admin/users/${userId}/load_entity_column?entity_type=${entityType}&base=${base}`;
    console.log('Fetching URL:', url);

    const startTime = performance.now();

    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
      .then(response => {
        const responseTime = performance.now() - startTime;
        console.log(`Response received in ${responseTime.toFixed(2)}ms`);
        console.log('Response status:', response.status);
        console.log('Response headers:', Object.fromEntries(response.headers.entries()));

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.text();
      })
      .then(html => {
        const totalTime = performance.now() - startTime;
        console.log(`HTML received in ${totalTime.toFixed(2)}ms`);
        console.log('HTML length:', html.length);
        console.log('HTML preview:', html.substring(0, 200) + '...');

        console.log('Replacing placeholder with loaded content');
        placeholder.outerHTML = html;

        console.log('Re-initializing Select2 and tooltips');
        // Re-initialize Select2 for the newly loaded content
        self.initSelect2();
        // Re-initialize tooltips
        document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new window.bootstrap.Tooltip(el));

        console.log('Successfully loaded entity column for:', entityType);
      })
      .catch(error => {
        console.error('Error loading entity column:', error);
        console.error('Error details:', {
          entityType,
          userId,
          url,
          error: error.message
        });

        placeholder.innerHTML = `
        <div class="alert alert-warning text-center p-4">
          <i class="icon-warning"></i>
          <p class="mt-2">Failed to load ${entityType.replace('_', ' ')}. Please refresh the page.</p>
          <small class="text-muted">Error: ${error.message}</small>
        </div>
      `;
      });
  }
};
