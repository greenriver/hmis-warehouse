class Affix {
  /**
   * constructor
   *
   * @param  {String} element  class or id of containing element
   * @param  {Number} offset   offset from top of page
   * @return NA
   */
  constructor({ element, offset, elementToPad}) {
    this.stuck = false
    this.affixing = false
    this.element = element
    this.elementOffset = offset
    this.elementToPad = elementToPad
    this.spy()
  }

  /**
   * spy - Add scroll event listener to window to determine stuck state
   *
   * @return {}
   */
  spy() {
    window.addEventListener("scroll", (event) => {
      if (this.affixing) return
      // Do nothing if page content is not of sufficent height to affix elements
      // if (this.element.clientHeight + this.element.offsetTop <= window.innerHeight) {
      //   if (this.stuck) this.affix(false)
      //   return
      // }
      this.affixing = true
      let elementOffsetTop = this.elementOffset
      // If on small screen hero image is not in view so set elementOffsetTop
      // to bottom of nav
      if (window.scrollY >= elementOffsetTop && !this.stuck) {
        this.affix(true)
      } else if (window.scrollY < elementOffsetTop && this.stuck) {
        this.affix(false)
      }
      this.affixing = false
    })
  }

  /**
   * affix - Add or remove classes which stick elements
   *
   * @param  {Boolean} stick Whether to stick or not
   * @return NA
   */
  affix(stick) {
    let classActionMethod = 'remove'

    if (stick) {
      classActionMethod = 'add'
    }

    if (this.elementToPad) {
      const padding = stick ? this.element.clientHeight + (this.element.style.marginBottom || 16) : 0
      const paddingTop = `${padding}px`
      this.elementToPad.style.paddingTop = paddingTop
    }

    this.stuck = stick
    document.body.classList[classActionMethod]('with-affixed-elements')
    this.element.classList[classActionMethod]('affixed')

  }
}

App.Affix = Affix
