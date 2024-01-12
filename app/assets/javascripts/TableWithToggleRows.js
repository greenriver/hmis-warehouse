window.App.TableWithToggleRows = class TableWithToggleRows {
  constructor(rowDomSelector) {
    this.rowDomSelector = rowDomSelector
    this.initEvents()
  }

  initEvents() {
    document.querySelectorAll(this.rowDomSelector).forEach((row) => {
      const self = this
      row.addEventListener('click', function(event) {
          self.toggleContent(row, event)
      })
    })
  }

  toggleContent(row, event) {
      if (event.target.href !== undefined) return
    if (row && row.nextElementSibling) {
      console.log(row, row.nextElementSibling)
      const content = row.nextElementSibling
      if (!content) return
      const icon =  row.querySelector('.table__toggle-icon')
      if (content.classList.contains('collapse'))  {
        row.classList.add('open')
        content.classList.remove('collapse')
        if (icon) icon.classList.add('toggled')
      } else {
        row.classList.remove('open')
        content.classList.add('collapse')
        if (icon) icon.classList.remove('toggled')
      }
    } else {
      return
    }
  }
}
