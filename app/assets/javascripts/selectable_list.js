class SelectableList {
  constructor(options) {
    this.title = options.title
    this.registerEvents()
  }

  /**
   * updateState - Update state of row
   *
   * @param  {Object} $el Jquery DOM Node
   * @return
   */
  updateState($el) {
    $el
      .toggleClass('children-visible')
      .next('.j-children')
      .toggleClass('d-table d-none')
  }

  /**
   * toggleElements - Show Children of clicked row
   *
   * @param  {Node} el           DOM Node
   * @param  {Object} event      Event
   * @param  {Boolean} getParent If true, element to take action against is parent
   * @return
   */
  toggleElements(el, event, getParent) {
    var $el = $(el)
    if (getParent) {
      $el = $(el).closest('.j-parent')
    }
    var nodeName = event ? event.target.nodeName : null
    var elements = ['INPUT', 'LABEL', 'BUTTON', 'A']
    if (elements.includes(nodeName)) {
      // Take no action for links or buttons
      if (nodeName === 'A' || nodeName === 'BUTTON') return
      // Open children if children are not visible
      if (!$el.hasClass('children-visible')) {
        this.updateState($el)
        event.stopPropagation()
        return false
      }
      return
    }
    this.updateState($el)
  }

  /**
   * checkParentAndChildren
   *
   * @param  {Object} event Event
   * @return
   */
  checkParentAndChildren(event) {
    var $el = $(event.currentTarget)
    var isChecked = $el.is(':checked')
    $el
      .closest('.j-parent')
      .next('.j-children')
      .find('.j-child-select')
      .prop('checked', isChecked)
  }

  /**
   * registerEvents - Register events controlling state and inputs
   *
   * @return
   */
  registerEvents() {
    const self = this
    $('.j-parent').on('click', function(event) { self.toggleElements(this, event, false) })
    $('.j-parent .j-select-children').on('change', this.checkParentAndChildren)
    $('.j-select-all').on('click', function() {
      var state = $(this).data('state')
      var btnClass = 'not-checked checked'
      $(this).data('state', !state)
      if (!state) { btnClass = 'checked not-checked'}
      $(this).toggleClass(btnClass)
      $('.j-parent')
        .find('.j-select-children')
        .prop('checked', !state)
        .trigger('change')
    })
  }
}

App.SelectableList = SelectableList
