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
    let $el = $(el)
    if (getParent) {
      $el = $(el).closest('.j-parent')
    }
    const nodeName = event ? event.target.nodeName : null
    const elements = ['INPUT', 'LABEL', 'BUTTON', 'A']
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
    const $el = $(event.currentTarget)
    const isChecked = $el.is(':checked')
    $el
      .closest('.j-parent')
      .next('.j-children')
      .find('.j-child-select')
      .prop('checked', isChecked)
  }

  /**
   * selectAllWithinScope - Select/deselect everything within DOM element
   *                        *Context of 'this' is clicked element
   *
   * @return {type}  description
   */
  selectAllWithinScope() {
    const { state, scope } = $(this).data()
    let btnClass = 'not-checked checked'
    $(this).data('state', !state)
    if (!state) { btnClass = 'checked not-checked'}
    $(this).toggleClass(btnClass)
    $(`${scope} .j-parent`)
      .find('.j-select-children')
      .prop('checked', !state)
      .trigger('change')
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
    $('.j-parent .j-select-children-btn').on('click', this.checkParentAndChildren)
    $('.j-select-all').on('click', this.selectAllWithinScope)
  }
}

App.SelectableList = SelectableList
