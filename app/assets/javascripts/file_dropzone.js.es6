window.App.FileDropzone = class FileDropzone {
  constructor(props) {
    this.props = props
    this.zone = $('<div>', { id: 'dropzone', text: 'Drop Your File to Upload' })

    this.init()
  }

  init() {
    // If we have a single file input on the page, initialize the zone
    if ($("input[type='file']").length == 1) {
      this.insert_dropzone($("input[type='file']")[0])
    }
    else {
      // If we have a single file input on the page after an ajax request, initialize the zone
      $(document).ajaxComplete((event, xhr, settings) => {
        if (typeof settings.headers !== 'undefined' && settings.headers['X-AJAX-MODAL']) {
          if ($("input[type='file']").length == 1) {
            this.insert_dropzone($("input[type='file']")[0])
          }
        }
      })
    }
  }

  showDropZone() {
    this.zone.css('display', 'flex')
  }

  hideDropZone() {
    this.zone.css('display', 'none')
  }

  insert_dropzone(file_input) {
    //create and insert dropzone
    this.zone.css({
      'box-sizing': 'border-box',
      'display': 'none',
      'position': 'fixed',
      'justify-content': 'center',
      'align-items': 'center',
      'width': '100%',
      'height': '100%',
      'left': '0',
      'top': '0',
      'z-index': '99999',

      'background': 'rgba(0, 0, 0, 0.5)',
      'border': 'dashed gray',
      'color': 'white',
      'font-weight': 'bold',
      'font-size': '40px'
    })
    $('body').prepend(this.zone)

    //add listeners for dropzone logic
    var showDrag = false
    var timeout = -1

    $(window).on('dragenter', (e) => {
      this.showDropZone()
      showDrag = true
    })

    $(window).on('dragover', (e) => {
      e.preventDefault()
      showDrag = true
    })

    $(window).on('dragleave', (e) => {
      showDrag = false
      clearTimeout(timeout)
      timeout = setTimeout(() => {
        if (!showDrag) { this.hideDropZone() }
      }, 200)
    })

    $(window).on('drop', (e) => {
      e.preventDefault()
      this.hideDropZone()
    })

    this.zone.on('drop', (e) => {
      this.hideDropZone()
      file_input.files = e.originalEvent.dataTransfer.files
    })
  }
}

new App.FileDropzone()
