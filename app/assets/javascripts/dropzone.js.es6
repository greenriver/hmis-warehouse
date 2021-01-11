var file_input_query = document.querySelectorAll("input[type='file']")
if (file_input_query.length == 1) {
    insert_dropzone(file_input_query[0])
}
  
function insert_dropzone(file_input) {
    //create and insert dropzone
    var $dropzone_div = $("<div>", {id: "dropzone", text: "Drop Your File to Upload"})
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
    showDrag = false
    timeout = -1
    function showDropZone() {
      $dropzone_div.css("display", "flex")
    }
    function hideDropZone() {
      $dropzone_div.css("display", "none")
    }

    window.addEventListener('dragenter', function(e) {
      showDropZone()
      showDrag = true
    })

    window.addEventListener('dragover', function(e) {
      e.preventDefault()
      showDrag = true
    })

    window.addEventListener('dragleave', function(e) {
      showDrag = false
      clearTimeout(timeout)
      timeout = setTimeout(function() {
        if (!showDrag) {hideDropZone()}
      }, 200)
    })

    window.addEventListener('drop', function(e) {
      e.preventDefault()
    })

    $dropzone_div.on('drop', function(event) {
      hideDropZone()
      file_input.files = event.originalEvent.dataTransfer.files
    })
}

