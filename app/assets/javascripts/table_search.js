App.TableSeach = class TableSeach {
  constructor(props) {
    this.props = props
    this.registerEvents()
  }

  registerEvents() {
    $(this.props.inputClass).on('input', (event) => {
      this.search(event.target.value)
    })
  }

  search(term) {
    $(this.props.rowClass).each(function() {
      if ($(this).data('title').indexOf(term.toLowerCase()) < 0) {
        $(this).addClass('hide')
        console.log('not a match')
      } else {
        $(this).removeClass('hide')
      }
    })
  }
}
