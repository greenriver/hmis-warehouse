import { Controller } from '@hotwired/stimulus';

const debounce = (func, wait) => {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
};

const MIN_SEARCH_LENGTH = 3;

// Generic client-side filtering of table rows by any number of select-driven facets plus a
// live text search (search does nothing below MIN_SEARCH_LENGTH characters).
//
//   %div{ data: { controller: 'table-filter' } }
//     %select{ data: { action: 'change->table-filter#filter', 'table-filter-target' => 'select', 'table-filter-field' => 'projectType' } }
//     %select{ data: { action: 'change->table-filter#filter', 'table-filter-target' => 'select', 'table-filter-field' => 'confidential' } }
//     %input{ data: { action: 'input->table-filter#debouncedFilter', 'table-filter-target' => 'searchInput' } }
//     %tr{ data: { 'table-filter-target' => 'row', 'project-type' => ..., confidential: ..., 'search-text' => ... } }
//       (rows may be grouped inside containers that hide once empty, each carrying 'group')
//     %div{ data: { 'table-filter-target' => 'noResults' } } shown when nothing matches
//
// A select's 'table-filter-field' value names the row dataset property it filters against
// (e.g. 'projectType' matches row.dataset.projectType); a select with no value is ignored.
export default class extends Controller {
  static targets = ['row', 'group', 'noResults', 'select', 'searchInput'];

  initialize() {
    this.debouncedFilter = debounce(() => this.filter(), 200);
  }

  connect() {
    this.filter();
  }

  // Select2 changes the select via jQuery's own trigger('change'), which (unlike
  // click/focus/submit) has no native DOM method for jQuery to call through to, so it
  // never reaches this controller's own change-> action. Bridge Select2's own selection
  // events to filter() directly instead (see content_loader_controller.js for the same fix).
  selectTargetConnected(el) {
    if (window.jQuery) window.jQuery(el).on('select2:select select2:unselect select2:clear', () => this.filter());
  }

  filter() {
    const activeFilters = this.selectTargets
      .map((select) => ({ field: select.dataset.tableFilterField, value: select.value }))
      .filter((filter) => filter.field && filter.value);
    const rawSearch = this.hasSearchInputTarget ? this.searchInputTarget.value.trim().toLowerCase() : '';
    const search = rawSearch.length >= MIN_SEARCH_LENGTH ? rawSearch : '';
    let anyVisible = false;

    for (const row of this.rowTargets) {
      const matchesFilters = activeFilters.every((filter) => row.dataset[filter.field] === filter.value);
      const matchesSearch = !search || (row.dataset.searchText || '').toLowerCase().includes(search);
      const matches = matchesFilters && matchesSearch;
      row.classList.toggle('hide', !matches);
      if (matches) anyVisible = true;
    }

    for (const group of this.groupTargets) {
      const hasVisibleRow = group.querySelector('[data-table-filter-target~="row"]:not(.hide)');
      group.classList.toggle('hide', !hasVisibleRow);
    }

    if (this.hasNoResultsTarget) this.noResultsTarget.classList.toggle('hide', anyVisible);
  }
}
