import { Controller } from "@hotwired/stimulus"

// Side menu behavior: the drawer below the on-canvas breakpoint, Back to Top,
// and widening the full-width menu by its scrollbar. Attached to <body> so it
// can reach both the header's hamburger and the menu itself.
export default class extends Controller {
  static get targets() {
    return ['menu', 'nav', 'toggle', 'backToTop'];
  }

  connect() {
    this.lastScrollY = window.scrollY;
    if (this.hasNavTarget && window.ResizeObserver) {
      // The nav's size changes when a scrollbar appears; its content's size
      // changes when sections expand or collapse.
      this.resizeObserver = new ResizeObserver(() => this.syncScrollbarWidth());
      this.resizeObserver.observe(this.navTarget);
      Array.from(this.navTarget.children).forEach((child) => this.resizeObserver.observe(child));
    }
  }

  disconnect() {
    this.resizeObserver?.disconnect();
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

  // At full width the nav scrolls on its own. A classic (always-shown)
  // scrollbar takes width from the labels and makes them wrap, so tell the CSS
  // how wide it is and the menu column grows to make room. Overlay scrollbars
  // take no width, so this stays 0 for them.
  syncScrollbarWidth() {
    const scrollbarWidth = this.navTarget.offsetWidth - this.navTarget.clientWidth;
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
