// Establish a debounce fn
// https://davidwalsh.name/javascript-debounce-function
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

// If condition is true, `$el` gets given class if not it's removed
const hideOrShowElement = (condition, $el, className = 'hide') => {
  if (condition) {
    $el.addClass(className);
  } else {
    $el.removeClass(className);
  }
};

// If condition is true, `$el` gets given class if not it's removed
const showOrHideElement = (condition, el, className = 'hide') => {
  if (condition) {
    el.classList.add(className);
  } else {
    el.classList.remove(className);
  }
};

// NOTE: The Stimulus controller that was previously in this file has been
// migrated to app/javascript/controllers/list_search_controller.js
// The ListSearch class below is still used by legacy Sprockets files.

window.App.ListSearch = class ListSearch {
  constructor(props) {
    this.props = props;
    this.search = debounce(this.search, 100);
    this.term = '';
    this.searchCategories = [];
    if (this.props.inputClass == '.j-table__search') {
      $(`${this.props.inputClass}.select2`).select2();
    }
    this.registerEvents();
  }

  registerEvents() {
    const self = this;
    $(this.props.inputClass).on('input select2:select select2:unselect', (event) => {
      if (event.target.nodeName === 'INPUT') {
        self.term = event.target.value;
      } else {
        // Store the selected categories
        self.searchCategories =
          [...event.target.querySelectorAll('option:checked')]
            .map((el) => el.getAttribute('value'));
      }
      this.search();
    });
  }

  search() {
    const term = this.term.toLowerCase();
    const $noItems = $(this.props.noItemsMessageSelector);
    let itemsFound = 0;
    $(this.props.itemClass).each((i, el) => {
      const $el = $(el);
      const text = $el.text().toLowerCase();
      const inCategory =
        !this.searchCategories.length ||
        this.searchCategories.includes($el.data('category'));
      const matchesTerm = text.indexOf(term) !== -1;
      if (inCategory && matchesTerm) {
        $el.removeClass('hide');
        itemsFound++;
      } else {
        $el.addClass('hide');
      }
    });
    this.showHideNoItemsMessage(!itemsFound);
  }

  showHideNoItemsMessage(show = false) {
    const $noItems = $(this.props.noItemsMessageSelector);
    if ($noItems.length) {
      if (show) {
        $noItems.removeClass('hide');
      } else {
        $noItems.addClass('hide');
      }
    }
  }
};
