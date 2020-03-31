window.App.TableWithToggleRows = class TableWithToggleRows {
  constructor(rowDomSelector) {
    this.rowDomSelector = rowDomSelector
    this.initEvents()
  }

  initEvents() {
    document.querySelectorAll(this.rowDomSelector).forEach((row) => {
      row.addEventListener('click', this.toggleContent.bind(this, row))
    })
  }

  toggleContent(row) {
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
