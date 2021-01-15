// Establish a debounce fn
// https://davidwalsh.name/javascript-debounce-function
const debounce = (func, wait, immediate) => {
	var timeout;
	return function() {
		var context = this, args = arguments;
		var later = function() {
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
const hideOrShowElement = (condition, $el, className='hide') => {
  if (condition) {
    $el.addClass(className)
  } else {
    $el.removeClass(className)
  }
}

// If condition is true, `$el` gets given class if not it's removed
const showOrHideElement = (condition, el, className='hide') => {
  if (condition) {
    el.classList.add(className)
  } else {
    el.classList.remove(className)
  }
}

App.StimulusApp.register('list-search', class extends Stimulus.Controller {
  static get targets() {
    return [ 'category', 'categoryContent', 'item', 'noResults' ]
  }

  initialize() {
    this.search = debounce(this.search, 200)
    this.selectedCategories = this.activeCategories()
    this.ACTIVE_CLASS = 'active'
    this.ALL_KEY = 'all'
    this.searchTerm = ''
  }

  changeCategory(event) {
    const el = event.target
    const { ACTIVE_CLASS, ALL_KEY } = this
    if (!el) return
    const { category } = el.dataset
    const allSelected = category === ALL_KEY
    if (allSelected) {
      this.selectAll()
    } else if ( this.selectedCategories.includes(category) ) {
      el.classList.remove(ACTIVE_CLASS)
    } else {
      this.categoryTargets[0].classList.remove(ACTIVE_CLASS)
      el.classList.add(ACTIVE_CLASS)
    }
    this.selectedCategories = this.activeCategories()
    if (!this.selectedCategories.length) {
      this.selectAll()
    }
    this.updateCategoryContent()
  }

  selectAll() {
    this.hideCategories(true)
    this.categoryTargets[0].classList.add(this.ACTIVE_CLASS)
  }

  hideCategories(categoriesToHide) {
    if (typeof(categoriesToHide) === 'boolean') {
      this.categoryTargets.forEach(el => el.classList.remove(this.ACTIVE_CLASS))
      return
    }
  }

  updateCategoryContent() {
    let activeCategoryKeys = this.activeCategories()
    if (activeCategoryKeys[0] === this.ALL_KEY) {
      activeCategoryKeys =
        this.categoryContentTargets.map(el => el.dataset.category)
    }
    this.categoryContentTargets.forEach((el) => {
      showOrHideElement(!activeCategoryKeys.includes(el.dataset.category), el)
    })
    if (this.searchTerm.length) {
      this.search(null)
    }
  }

  activeCategories() {
    return this.categoryTargets
      .map(el => el.classList.contains(this.ACTIVE_CLASS) ? el.dataset.category : null)
      .filter(x => x)
  }

  search(event) {
    let term = ''
    let foundCount = 0
    if (event) {
      const { target } = event
      term = target.value
    } else {
      term = this.searchTerm
    }
    let activeCategoriesEls =
      this.categoryContentTargets.filter( el => !el.classList.contains('hide') )
      activeCategoriesEls.forEach((group) => {
        const matchingItems = [...group.querySelectorAll('li')].filter((item) => {
          if (!term.length) {
            showOrHideElement(false, item)
            return true
          }
          const { title='' } = item.dataset
          const description = item.querySelector('p')
          const termRegExp = new RegExp(term, 'i')
          const matches = [
            title ? title.match(termRegExp) : false,
            description ? description.textContent.match(termRegExp) : false
          ]
          const itemMatches = matches.some(v => v)
          showOrHideElement(!itemMatches, item)
          return itemMatches
        })
        foundCount += matchingItems.length
        showOrHideElement(!matchingItems.length && term.length, group, 'no-results')
      })
    this.searchTerm = term
    showOrHideElement(foundCount, this.noResultsTarget)
  }
})

window.App.ListSearch = class ListSearch {
  constructor(props) {
    this.props = props
    this.search = debounce(this.search, 100)
    this.term = ''
    this.searchCategories = []
    if (this.props.initSelect2) {
      $(`${this.props.inputClass}.select2`).select2()
    }
    this.registerEvents()
  }

  registerEvents() {
    const self = this
    $(this.props.inputClass).on('input select2:select select2:unselect', (event) => {
      if (event.target.nodeName === 'INPUT' ) {
        self.term = event.target.value
      } else {
        // Store the selected categories
        self.searchCategories =
          [...event.target.querySelectorAll('option:checked')]
            .map( (el) => el.getAttribute('value') )
      }
      this.search()
    })
  }

  search() {
    const { props, term, searchCategories } = this
    const { itemClass, groupClass=null } = props
    new Promise(function(complete) {
      let query = itemClass
      if (searchCategories.length) {
        // Add categories to query to enable searching items under category by term
        query = searchCategories.map((cat) => {
          return `${groupClass || itemClass}[data-categories*='${cat}'] ${groupClass ? itemClass : ''}`.trim()
        }).join(', ')
        // Hide category groups or items matching category if items are not grouped
        $(groupClass || itemClass).each((i, cat) => {
          const $cat = $(cat)
          hideOrShowElement(!searchCategories.includes($cat.data('categories')), $cat)
        })
      } else {
        hideOrShowElement(false, $(groupClass))
      }

      if (term) {
        const $items = $(query)
        // No-op if string is short
        if (term.length <= 2) complete()
        $items.each((i, el) => {
          const title = $(el).data('title') || ''
          const description = $(el).find('p').text()
          const termRegExp = new RegExp(term, 'i')
          const matches = [
            title ? title.match(termRegExp) : false,
            description ? description.match(termRegExp) : false
          ]
          hideOrShowElement(!matches.some(v => v), $(el))
          if (i == $items.length-1) complete()
        })
      } else {
        // Show all items
        $(query).each( (i, el) => hideOrShowElement(false, $(el)) )
        complete()
      }

    }).then(() => {
      // Hide group if all the items within are hidden
      if (term.length && !searchCategories.length) {
        $(groupClass).each((i, el) => {
          const $groupContainer = $(el)
          const allItemsHidden =
            $groupContainer.find(itemClass).length === $groupContainer.find(`${itemClass}.hide`).length
          hideOrShowElement(allItemsHidden, $groupContainer)
        })
      }
      // Show message if all hidden
      this.showHideNoItemsMessage(!$(`${itemClass}:visible`).length)
    })
  }
  showHideNoItemsMessage(show=false) {
    const messageClass = 'no-results'
    const { containerClass='.DTFC_LeftHeadWrapper' } = this.props
    if (show) {
      let categoryMessage = ''
      let termMessage = ''
      const {term, searchCategories } = this
      if (term.length > 2) {
        termMessage = ` matching <strong>${term}</strong>`
      }
      if (searchCategories.length) {
        categoryMessage = ` in <strong>${searchCategories.join(', ')}</strong>`
      }
      const message = `No results found${termMessage}${categoryMessage}.`
      const messageEl = $(`.${messageClass}`)
      if (messageEl.length) {
        messageEl.html(message)
      } else {
        $(containerClass).append(`<p class=${messageClass}>${message}</p>`)
      }
    } else {
      $(`.${messageClass}`).remove()
    }
  }
}
