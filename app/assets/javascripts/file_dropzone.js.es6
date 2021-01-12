window.App.FileDropzone = class FileDropzone {
  constructor(props) {
    this.props = props

    let file_input_query = document.querySelectorAll("input[type='file']")
    if (file_input_query.length == 1) {
      this.insert_dropzone(file_input_query[0])
    }
  }

  insert_dropzone(file_input) {
    //create and insert dropzone
    let $dropzone_div = $("<div>", {id: "dropzone", text: "Drop Your File to Upload"})
    $dropzone_div.css({
        "box-sizing": "border-box",
        "display": "none",
        "position": "fixed",
        "justify-content": "center",
        "align-items": "center",
        "width": "100%",
        "height": "100%",
        "left": "0",
        "top": "0",
        "z-index": "99999",

        "background": "rgba(0, 0, 0, 0.5)",
        "border": "dashed gray",
        "color": "white",
        "font-weight": "bold",
        "font-size": "40px"
    })
    $("body").prepend($dropzone_div)

    //add listeners for dropzone logic
    var showDrag = false
    var timeout = -1
    function showDropZone() {
      $dropzone_div.css("display", "flex")
    }
    function hideDropZone() {
      $dropzone_div.css("display", "none")
    }

    $(window).on('dragenter', function(e) {
      showDropZone()
      showDrag = true
    })

    $(window).on('dragover', function(e) {
      e.preventDefault()
      showDrag = true
    })

    $(window).on('dragleave', function(e) {
      showDrag = false
      clearTimeout(timeout)
      timeout = setTimeout(function() {
        if (!showDrag) {hideDropZone()}
      }, 200)
    })

    $(window).on('drop', function(e) {
      e.preventDefault()
    })

    $dropzone_div.on('drop', function(e) {
      hideDropZone()
      file_input.files = e.originalEvent.dataTransfer.files
    })
  }
}
  
new App.FileDropzone()