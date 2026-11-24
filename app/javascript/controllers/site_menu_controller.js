import { Controller } from "@hotwired/stimulus"

// Side menu behavior: the drawer below the on-canvas breakpoint, Back to Top,
// and widening the menu by its scrollbar. Attached to <body> so it
// can reach both the header's hamburger and the menu itself.
export default class extends Controller {
  static get targets() {
    return ['menu', 'nav', 'toggle', 'backToTop'];
  }

  connect() {
    this.lastScrollY = window.scrollY;
    if (this.hasNavTarget && window.ResizeObserver) {
      // The nav's scrollbar gutter is reserved (scrollbar-gutter: stable) in
      // both the drawer and full-width layouts, so its width only changes when
      // the page is zoomed, which resizes the nav.
      // Defer to the next frame: widening the menu resizes the observed nav,
      // and doing that inside the callback makes the browser fire "ResizeObserver
      // loop completed with undelivered notifications".
      this.resizeObserver = new ResizeObserver(() => {
        cancelAnimationFrame(this.syncFrame);
        this.syncFrame = requestAnimationFrame(() => this.syncScrollbarWidth());
      });
      this.resizeObserver.observe(this.navTarget);
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect();
    cancelAnimationFrame(this.syncFrame);
  }

  get isOpen() {
    return this.element.classList.contains('menu-open');
  }

  toggle(event) {
    event.preventDefault();
    this.setOpen(!this.isOpen);
  }

  closeOnEscape(event) {
    if (event.key !== 'Escape' || !this.isOpen) return;

    this.setOpen(false);
    if (this.hasToggleTarget) this.toggleTarget.focus();
  }

  closeOnOutsideClick(event) {
    if (!this.isOpen) return;
    if (this.menuTargets.some((menu) => menu.contains(event.target))) return;
    if (this.toggleTargets.some((toggle) => toggle.contains(event.target))) return;

    this.setOpen(false);
  }

  setOpen(open) {
    if (open) {
      // Open the drawer just below the header, which moves down when warning
      // bars render above it.
      const header = document.querySelector('.o-header--page');
      const drawerTop = Math.max(0, header?.getBoundingClientRect().bottom ?? 0);
      this.menuTargets.forEach((menu) => menu.style.setProperty('--o-menu-drawer-top', `${drawerTop}px`));
    }
    this.element.classList.toggle('menu-open', open);
    this.menuTargets.forEach((menu) => {
      menu.classList.toggle('on-canvas', open);
      menu.classList.toggle('off-canvas', !open);
    });
    this.toggleTargets.forEach((toggle) => toggle.setAttribute('aria-expanded', String(open)));
  }

  // The nav scrolls on its own and always reserves room for a scrollbar. A
  // classic (always-shown) scrollbar's gutter takes width from the labels and
  // makes them wrap, so tell the CSS how wide it is and the menu grows to make
  // room. Overlay scrollbars take no width, so this stays 0 for them.
  syncScrollbarWidth() {
    const scrollbarWidth = this.navTarget.offsetWidth - this.navTarget.clientWidth;
    // Widening the menu triggers the observer again; stop once it's settled.
    if (scrollbarWidth === this.scrollbarWidth) return;

    this.scrollbarWidth = scrollbarWidth;
    this.menuTargets.forEach((menu) => menu.style.setProperty('--o-menu-scrollbar-width', `${scrollbarWidth}px`));
  }

  backToTop(event) {
    event.preventDefault();
    const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    window.scrollTo({ top: 0, behavior: reduceMotion ? 'auto' : 'smooth' });
  }

  // Show Back to Top once the user is a quarter of the way down the window
  // and scrolling back up.
  updateBackToTop() {
    if (!this.hasBackToTopTarget) return;

    const scrollY = window.scrollY;
    const show = scrollY > window.innerHeight / 4 && this.lastScrollY > scrollY;
    this.backToTopTarget.classList.toggle('active', show);
    this.lastScrollY = scrollY;
  }
}
