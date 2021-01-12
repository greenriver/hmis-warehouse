window.App.FileDropzone = class FileDropzone {
  constructor(props) {
    this.props = props
    this.$dropzone_div = $("<div>", {id: "dropzone", text: "Drop Your File to Upload"})
    this.dropzone_inserted = false
    this.dropzone_enabled = false

    this.init()
  }

  init() {
    //initiate dropzone if there is 1 file input on page
    let file_input_query = $("input[type='file']")
    let file_input_on_page = file_input_query.length == 1
    if (file_input_on_page) {
      this.process_dropzone(file_input_query[0])
    }

    //set up listener for ajax modals with file inputs
    $(document).ajaxComplete((event, xhr, settings) => {
      if (typeof settings.headers !== 'undefined' && settings.headers["X-AJAX-MODAL"]) {
        let file_input_in_model_query = $("div[id='ajax-modal'] input[type='file']")
        console.log(file_input_in_model_query)
        if (file_input_in_model_query.length == 1) {
          this.process_dropzone(file_input_in_model_query[0])
        }
      }
    })

    //listener for when modal close
    //if there are no input on page, just disable the dropzone
    //else, set the file input of dropzone back to original
    $("div.modal[id='ajax-modal']").on("modalClose", () => {
      if (file_input_on_page) {
        this.process_dropzone(file_input_query[0])
      } else {
        this.disable_dropzone()
      }
    })
  }

  //insert/enable the dropzone if not and update dz file stream
  //essentially an on switch
  process_dropzone(file_input) {
    if (!this.dropzone_inserted) { this.insert_dropzone() }
    if (!this.dropzone_enabled) { this.enable_dropzone() }
    this.update_drop_file_stream(file_input)
  }

  //insert dropzone, or basically inserting css and prepending it to body
  insert_dropzone() {
    this.dropzone_inserted = true

    this.$dropzone_div.css({
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
    $("body").prepend(this.$dropzone_div)
  }

  //enable dropzone, or turn on event listeners
  enable_dropzone() {
    this.dropzone_enabled = true
    
    //add listeners for dropzone logic
    var showDrag = false
    var timeout = -1
    
    console.log("HUH")

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
        if (!showDrag) {this.hideDropZone()}
      }, 200)
    })
  }

  //turn off event listeners
  disable_dropzone() {
    this.dropzone_enabled = false

    //disable dropzone after modal close
    $(window).off('dragenter')
    $(window).off('dragover')
    $(window).off('dragleave')
    $(window).off('drop')
  }

  //update dropzone file stream
  update_drop_file_stream(file_input) {
    $(window).off('drop') //turn off previous event
    $(window).on('drop', (e) => {
      e.preventDefault()
      this.hideDropZone()
      file_input.files = e.originalEvent.dataTransfer.files
    })
  }

  showDropZone() {
    this.$dropzone_div.css("display", "flex")
  }

  hideDropZone() {
    this.$dropzone_div.css("display", "none")
  }
}
  
new App.FileDropzone()