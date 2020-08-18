window.App.TableSearch = class TableSearch {
  constructor(props) {
    this.props = props
    this.registerEvents()
  }

  registerEvents() {
    $(this.props.inputClass).on('input select2:select select2:unselect', (event) => {
      this.search(event.target.value, event)
    })
  }

  search(term, event) {
    $(this.props.rowClass).each(function() {
      let match = false
      let searchCategories = []
      const itemCategories = $(this).data('categories')
      const title = $(this).data('title')

      if (event.target.nodeName === 'SELECT') {
        searchCategories =
          [...event.target.querySelectorAll('option:checked')]
            .map( (el) => el.getAttribute('value') )
      }
      match = title.match(term, 'i') || searchCategories.some(cat=> itemCategories.includes(cat))
      if (!match) {
        $(this).addClass('hide')
      } else {
        $(this).removeClass('hide')
      }
    })
  }
}
