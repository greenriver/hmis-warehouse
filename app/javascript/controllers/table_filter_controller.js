import { Controller } from '@hotwired/stimulus';

const debounce = (func, wait) => {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
};

const MIN_SEARCH_LENGTH = 3;

// Client-side filtering of project rows by Project Type, Confidential status, and a
// live text search (search does nothing below MIN_SEARCH_LENGTH characters).
//
//   %div{ data: { controller: 'table-filter' } }
//     %select{ data: { action: 'change->table-filter#filter', 'table-filter-target' => 'projectTypeSelect' } }
//     %select{ data: { action: 'change->table-filter#filter', 'table-filter-target' => 'confidentialSelect' } }
//     %input{ data: { action: 'input->table-filter#debouncedFilter', 'table-filter-target' => 'searchInput' } }
//     %tr{ data: { 'table-filter-target' => 'row', 'project-type' => ..., confidential: ..., 'search-text' => ... } }
//       (rows grouped inside per-organization cards, each carrying 'orgGroup')
//     %div{ data: { 'table-filter-target' => 'noResults' } } shown when nothing matches
//
export default class extends Controller {
  static targets = ['row', 'orgGroup', 'noResults', 'projectTypeSelect', 'confidentialSelect', 'searchInput'];

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
  projectTypeSelectTargetConnected(el) {
    this.bridgeSelect2Changes(el);
  }

  confidentialSelectTargetConnected(el) {
    this.bridgeSelect2Changes(el);
  }

  bridgeSelect2Changes(el) {
    if (window.jQuery) window.jQuery(el).on('select2:select select2:unselect select2:clear', () => this.filter());
  }

  filter() {
    const projectType = this.projectTypeSelectTarget.value;
    const confidential = this.confidentialSelectTarget.value;
    const rawSearch = this.hasSearchInputTarget ? this.searchInputTarget.value.trim().toLowerCase() : '';
    const search = rawSearch.length >= MIN_SEARCH_LENGTH ? rawSearch : '';
    let anyVisible = false;

    for (const row of this.rowTargets) {
      const matchesType = !projectType || row.dataset.projectType === projectType;
      // Treat anything other than an explicit "true" as not-confidential, so a missing/blank
      // attribute (e.g. a null underlying value) still counts as "Not confidential" rather than
      // being excluded from both filter options.
      const matchesConfidential = !confidential || (confidential === 'true' ? row.dataset.confidential === 'true' : row.dataset.confidential !== 'true');
      const matchesSearch = !search || (row.dataset.searchText || '').toLowerCase().includes(search);
      const matches = matchesType && matchesConfidential && matchesSearch;
      row.classList.toggle('hide', !matches);
      if (matches) anyVisible = true;
    }

    for (const group of this.orgGroupTargets) {
      const hasVisibleRow = group.querySelector('[data-table-filter-target~="row"]:not(.hide)');
      group.classList.toggle('hide', !hasVisibleRow);
    }

    if (this.hasNoResultsTarget) this.noResultsTarget.classList.toggle('hide', anyVisible);
  }
}
