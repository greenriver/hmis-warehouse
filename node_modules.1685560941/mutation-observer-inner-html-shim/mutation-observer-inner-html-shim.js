if (window.MutationObserver) {
  var element = document.createElement("div")
  element.innerHTML = "<div><div></div></div>"

  new MutationObserver(function(mutations, observer) {
    observer.disconnect()
    if (
      mutations[0] &&
      mutations[0].type == "childList" &&
      mutations[0].removedNodes[0].childNodes.length == 0
    ) {
      var prototype = HTMLElement.prototype
      var descriptor = Object.getOwnPropertyDescriptor(prototype, "innerHTML")
      if (descriptor && descriptor.set) {
        Object.defineProperty(prototype, "innerHTML", {
          set: function(value) {
            while (this.lastChild) this.removeChild(this.lastChild)
            descriptor.set.call(this, value)
          }
        })
      }
    }
  }).observe(element, { childList: true, subtree: true })

  element.innerHTML = ""
}
