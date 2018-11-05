App.ViewableEntities = class {
  constructor() {
    this.registerEvents()
    this.initSelect2()
  }

  registerEvents() {
    const self = this
    const showHideEl = (event, relatedElement) => {
      event.preventDefault()
      const $container = $(event.currentTarget).closest('.j-column')
      const $element = $container.find('.j-column-actions-' + relatedElement)
      const $content = $container.find('.j-column-content')
      $element.siblings().addClass('hide')
      $element.toggleClass('hide')
      $content.toggleClass('active')
      let select2Action = 'open'
      let contentAction = 'addClass'
      if ($element.hasClass('hide')) {
        select2Action = 'close'
        contentAction = 'removeClass'
      }
      $content[contentAction]('inactive')
      $element.find('.jUserViewable').select2(select2Action)
    }

    const getSelect2 = (el) => {
      return $(el).closest('.j-column').find('.jUserViewable')
    }

    $('.j-add').on('click', (event) => {
      const elements = showHideEl(event, 'add')
    })
    $('.j-remove-all-toggle').on('click', (event) => {
      const elements = showHideEl(event, 'remove')
    })
    $('.j-remove-all').on('click', function (event) {
      self.removeAll(getSelect2(this), $(this).closest('.j-column'))
    })
    $('.j-list').on('click', 'li', function (event) {
      self.removeItem(this, getSelect2(this))
    })
  }

  renderList(items, $list) {
    const $container = $list.closest('.j-column')
    const $listContainer = $container.find('.j-list')
    const ids = Object.keys(items)
    const itemsMarkup = Object.values(items).map((item, i) => `
      <li class='c-columns__column-list-item' data-id=${ids[i]}>
        <span>${item}</span>
        <span> <i class='fas fa-times-circle'></i></span>
      </li>
    `).join('')
    const hasAssociated = $listContainer.siblings().first().children().length
    let noDataMessage = '<li class="c-columns__column-list-item--read-only font-italic">No ' + this.getEntityName($container) + ' selected.</li>'
    if (hasAssociated) {
      noDataMessage = ''
    }
    $listContainer.html(itemsMarkup || noDataMessage)

  }

  getEntityName($column) {
    return $column.data('title') || ''
  }

  removeAll($select2, $container) {
    $select2
      .val('')
      .trigger('change')
    $container.find('.j-list').html('')
    $container.find('.j-column-actions-remove').addClass('hide')
  }

  removeItem(item, $select2) {
    const currentIds = $select2.val()
    const index = currentIds.indexOf($(item).data('id').toString())
    if (index > -1) {
      currentIds.splice(index, 1);
    }
    $select2
      .val(currentIds)
      .trigger('change')
    item.remove()
  }

  initSelect2() {
    const self = this
    $('.jClearSelect').on('click', function(event) {
      event.preventDefault()
      var select_class = $(event.currentTarget).data('input-class');
      $("select." + select_class).find('option:selected').prop("selected", false);
      return $("select." + select_class).trigger('change');
    })

    const values = function($this, includeSelected=false) {
      let query = 'option[selected]'
      if (includeSelected) {
        query = ':selected'
      }
      const $selectedOptions = $this.find(query);
      const values = $this.val()
      const selected = {}
      $selectedOptions.each(function(i, el) {
        selected[el.value] = el.textContent
      })
      self.renderList(selected, $this)
      return selected
    }

    const init = ($this) => {
      return $(function() {
        $this.select2({
          minimumResultsForSearch: 10,
          placeholder: 'Search for ' + $this.attr('placeholder'),
          tags: false,
          multiple: true
        })
        $this.val(Object.keys(values($this))).trigger('change');
      })
    }

    $('.jUserViewable').each(function() {
      const $this = $(this)
      $this.on('select2:select select2:unselect', function(){
        self.renderList(values($(this), true), $(this))
      })
      init($this)
    })
  }
}
