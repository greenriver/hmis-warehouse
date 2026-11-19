import * as bootstrap from "bootstrap"

// Popovers are delegated from document.body so ones in content added later (ajax modals) also work.
// A delegated instance applies one trigger to every match, so there is one instance per trigger.
// Elements with data-bs-trigger="manual" are shown by their own scripts.
const popoverAllowList = {
  ...bootstrap.Popover.Default.allowList,
  // The client info popover (/api/clients/:id) and the unmerge Match Details render tables.
  table: [], thead: [], tbody: [], tr: [], th: [], td: [],
  abbr: ['title'],
}
const popoverContent = new WeakMap()

const popoverFetching = new WeakSet()

const contentFor = (element) => {
  if (popoverContent.has(element)) return popoverContent.get(element)
  // Never rendered; non-empty content lets Bootstrap fire show.bs.popover so the URL can load.
  if (element.dataset.bsUrl) return 'Loading...'
  return element.getAttribute('data-bs-content') || ''
}

// Bootstrap hides a click popover whose content is replaced after it is shown, so content loads before the first show.
const loadPopoverContent = (element) => {
  popoverFetching.add(element)
  fetch(element.dataset.bsUrl, {
    credentials: 'same-origin',
    headers: { Accept: 'text/html', 'X-Requested-With': 'XMLHttpRequest' },
  })
    .then(response => (response.ok ? response.text() : Promise.reject(new Error(response.status))))
    .then(html => ({ html, failed: false }))
    .catch(() => ({ html: 'Unable to load', failed: true }))
    .then(({ html, failed }) => {
      popoverFetching.delete(element)
      popoverContent.set(element, html)
      try {
        bootstrap.Popover.getInstance(element)?.show()
      } finally {
        // The tip is built synchronously by show(), so a failure is not cached and the next open retries.
        if (failed) popoverContent.delete(element)
      }
    })
}

const handlePopoverShow = (event) => {
  const element = event.target
  if (!element.dataset?.bsUrl || popoverContent.has(element)) return
  event.preventDefault()
  if (!popoverFetching.has(element)) loadPopoverContent(element)
}

const popoverSelector = '[data-bs-toggle="popover"]'
const popoverTriggers = {
  click: `${popoverSelector}:not([data-bs-trigger]), ${popoverSelector}[data-bs-trigger="click"]`,
  focus: `${popoverSelector}[data-bs-trigger="focus"]`,
  hover: `${popoverSelector}[data-bs-trigger="hover"]`,
}

export function initializePopovers() {
  Object.entries(popoverTriggers).forEach(([trigger, selector]) => {
    new bootstrap.Popover(document.body, {
      selector,
      trigger,
      content: contentFor,
      allowList: popoverAllowList,
    })
  })
  document.addEventListener('show.bs.popover', handlePopoverShow)
  document.addEventListener('click', event => {
    if (event.target.closest(`a[href="#"]${popoverSelector}`)) event.preventDefault()
  })
}
