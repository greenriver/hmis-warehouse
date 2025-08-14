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

export default class extends Controller {
  static get targets() {
    return [
      'category',
      'categoryContent',
      'item',
      'results',
      'noResults',
      'foundCount',
      'searchAll'
    ];
  }

  initialize() {
    this.ACTIVE_CLASS = 'active';
    this.ALL_KEY = 'all';
    this.searchTerm = '';
    this.search = debounce(this.search, 300);
    this.initCategories();
  }

  initCategories() {
    this.selectedCategories = this.activeCategories();
    const activeCategoryHash = window.location.hash;
    if (activeCategoryHash) {
      this.changeCategory(
        null,
        this.categoryTargets.find((el) => {
          return el.dataset.hash === activeCategoryHash.substring(1);
        })
      );
    }
  }

  changeCategory(event, categoryTarget = null) {
    const el = categoryTarget || event.target;
    if (!el) return;
    if (this.selectedCategories === el) {
      return;
    }
    const { category, hash } = el.dataset;
    if (hash) {
      window.location.hash = hash;
    }
    else {
      window.location.hash = '';
    }
    if (category === this.ALL_KEY) {
      this.selectAll();
    } else {
      this.hideAllCategories();
      el.classList.add(this.ACTIVE_CLASS);
      el.setAttribute('aria-pressed', true);
    }
    showOrHideElement(category === this.ALL_KEY, this.searchAllTarget);
    this.selectedCategories = this.activeCategories();
    this.updateCategoryContent();
  }

  keyboardChangeCategory(e) {
    if (e.keyCode == 13) {
      this.changeCategory(e);
    }
  }

  selectAll() {
    this.hideAllCategories();
    this.categoryTargets[0].classList.add(this.ACTIVE_CLASS);
  }

  hideAllCategories() {
    this.categoryTargets.forEach(el => {
      el.classList.remove(this.ACTIVE_CLASS);
      el.setAttribute('aria-pressed', false);
    });
  }

  updateCategoryContent() {
    let activeCategoryKeys = this.activeCategories();
    if (activeCategoryKeys[0] === this.ALL_KEY) {
      activeCategoryKeys =
        this.categoryContentTargets.map(el => el.dataset.category);
    }
    this.categoryContentTargets.forEach((el) => {
      showOrHideElement(!activeCategoryKeys.includes(el.dataset.category), el);
    });
    if (this.searchTerm.length) {
      this.search(null);
    }
  }

  activeCategories(getContentElements = false) {
    if (getContentElements) {
      return this.categoryContentTargets.filter((el) => (
        !el.classList.contains('hide')
      ));
    } else {
      return this.categoryTargets
        .map(el => el.classList.contains(this.ACTIVE_CLASS) ? el.dataset.category : null)
        .filter(x => x);
    }
  }

  setSearchingState(state) {
    if (state) {
      this.resultsTarget.classList.add('searching');
    } else {
      this.resultsTarget.classList.remove('searching');
    }
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

  search(event) {
    let term = '';
    let foundCount = 0;
    if (event) {
      const { target } = event;
      term = target.value;
    } else {
      term = this.searchTerm;
    }
    this.setSearchingState(true);
    const activeCategoryContent = this.activeCategories(true);
    return new Promise((finishSearch) => {
      activeCategoryContent.forEach((group, groupIndex) => {
        const searchGroupItems = (groupItems) => {
          return new Promise((finishItemSearch) => {
            let foundItemCount = 0;
            if (groupItems.length == 0) {
              finishItemSearch(foundItemCount);
            }
            groupItems.forEach((item, itemIndex) => {
              if (!term.length) {
                showOrHideElement(false, item);
                finishItemSearch(groupItems.length);
              }
              const { title = '' } = item.dataset;
              const description = item.querySelector('p');
              const termRegExp = new RegExp(term, 'i');
              const matches = [
                title ? title.match(termRegExp) : false,
                description ? description.textContent.match(termRegExp) : false
              ];
              const itemMatches = matches.some(v => v);
              showOrHideElement(!itemMatches, item);
              if (itemMatches) {
                foundItemCount++;
              }
              if (groupItems.length === itemIndex + 1) {
                finishItemSearch(foundItemCount);
              }
            });
          });
        };
        searchGroupItems([...group.querySelectorAll('li')])
          .then((groupItemCount) => {
            foundCount += groupItemCount;
            showOrHideElement(!groupItemCount && term.length, group, 'no-results');
            if (activeCategoryContent.length === groupIndex + 1) {
              this.updateFoundCount(term.length, foundCount);
              if (this.hasNoResultsTarget) {
                showOrHideElement(foundCount === 0, this.noResultsTarget);
              }
              this.setSearchingState(false);
              this.searchTerm = term;
              finishSearch(foundCount);
            }
          });
      });
    });
  }
}
