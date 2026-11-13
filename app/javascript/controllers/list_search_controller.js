import { Controller } from "@hotwired/stimulus"

const debounce = (func, wait, immediate) => {
  var timeout;
  return function () {
    var context = this, args = arguments;
    var later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    var callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
};

const showOrHideElement = (condition, el, className = 'hide') => {
  if (condition) {
    el.classList.add(className);
  } else {
    el.classList.remove(className);
  }
};

// Search is its own mode: a term searches every report and deselects all categories;
// choosing a category clears the term.
export default class extends Controller {
  static get targets() {
    return [
      'category',
      'categoryContent',
      'input',
      'noResults',
      'foundCount'
    ];
  }

  initialize() {
    this.ACTIVE_CLASS = 'active';
    this.ALL_KEY = 'all';
    this.search = debounce(this.search, 300);
    this.initCategories();
  }

  // Links to a category from elsewhere on the page (e.g. the site menu) only change the hash.
  connect() {
    this.onHashChange = () => this.initCategories();
    window.addEventListener('hashchange', this.onHashChange);
  }

  disconnect() {
    window.removeEventListener('hashchange', this.onHashChange);
  }

  initCategories() {
    const activeCategoryHash = window.location.hash;
    // An empty hash (e.g. navigating back to the "All" view) selects the first ("all") category.
    const target = activeCategoryHash
      ? this.categoryTargets.find((el) => el.dataset.hash === activeCategoryHash.substring(1))
      : this.categoryTargets[0];
    this.changeCategory(null, target);
  }

  changeCategory(event, categoryTarget = null) {
    const el = categoryTarget || event.target;
    if (!el) return;
    const { category, hash } = el.dataset;
    if (!this.searchTerm() && el.classList.contains(this.ACTIVE_CLASS)) {
      return;
    }
    this.clearSearch();
    window.location.hash = hash || '';
    this.deselectAllCategories();
    el.classList.add(this.ACTIVE_CLASS);
    el.setAttribute('aria-pressed', true);
    this.categoryContentTargets.forEach((group) => {
      showOrHideElement(category !== this.ALL_KEY && group.dataset.category !== category, group);
    });
  }

  keyboardChangeCategory(e) {
    if (e.keyCode == 13) {
      this.changeCategory(e);
    }
  }

  deselectAllCategories() {
    this.categoryTargets.forEach(el => {
      el.classList.remove(this.ACTIVE_CLASS);
      el.setAttribute('aria-pressed', false);
    });
  }

  searchTerm() {
    return this.hasInputTarget ? this.inputTarget.value.trim().toLowerCase() : '';
  }

  clearSearch() {
    if (this.hasInputTarget) this.inputTarget.value = '';
    this.element.querySelectorAll('li.hide').forEach(item => item.classList.remove('hide'));
    this.updateFoundCount(false);
    showOrHideElement(true, this.noResultsTarget);
  }

  search() {
    const term = this.searchTerm();
    if (!term) {
      this.changeCategory(null, this.categoryTargets[0]);
      return;
    }
    this.deselectAllCategories();
    // replaceState clears the hash without firing hashchange, which would reselect a category.
    history.replaceState(null, '', window.location.pathname + window.location.search);

    let foundCount = 0;
    this.categoryContentTargets.forEach((group) => {
      // Recently Viewed and Favorites repeat reports from the other groups.
      if ('searchExcluded' in group.dataset) {
        showOrHideElement(true, group);
        return;
      }
      let groupCount = 0;
      group.querySelectorAll('li').forEach((item) => {
        const title = item.dataset.title || '';
        const description = item.querySelector('p')?.textContent || '';
        const matches = `${title} ${description}`.toLowerCase().includes(term);
        showOrHideElement(!matches, item);
        if (matches) groupCount++;
      });
      showOrHideElement(!groupCount, group);
      foundCount += groupCount;
    });
    this.updateFoundCount(true, foundCount);
    showOrHideElement(foundCount > 0, this.noResultsTarget);
  }

  updateFoundCount(show = false, count) {
    if (!this.hasFoundCountTarget) return;
    if (show) {
      this.foundCountTarget.classList.remove('hide');
      this.foundCountTarget.querySelector('.count').innerHTML = count;
    } else {
      this.foundCountTarget.classList.add('hide');
    }
  }
}
