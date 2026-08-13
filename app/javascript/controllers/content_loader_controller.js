import { Controller } from '@hotwired/stimulus';

// Reloads an HTML fragment when a control changes.
//
//   %div{ data: { controller: 'content-loader', content_loader_url_value: some_path } }
//     = select_tag :coc_code, options_for_select(options), include_blank: 'Select a CoC Code',
//       data: { action: 'change->content-loader#load', content_loader_target: 'param' }
//     %div{ data: { content_loader_target: 'results' } }
//       Empty-state markup; restored if required params are blank.
//
export default class extends Controller {
  static targets = ['results', 'param'];
  static values = { url: String, historyUrl: String };

  resultsTargetConnected(el) {
    if (!this.promptHtml) this.promptHtml = el.innerHTML;
  }

  paramTargetConnected(el) {
    // Select2 changes the select via jQuery's own trigger('change'), which
    // (unlike click/focus/submit) has no native DOM method for jQuery to
    // call through to, so it never reaches this native change-> action.
    // Bridge Select2's own selection events to load() directly instead.
    if (window.jQuery) window.jQuery(el).on('select2:select select2:unselect select2:clear', () => this.load());
  }

  load() {
    const params = this.paramQuery();
    this.updateHistoryUrl();
    if (!params) {
      this.resultsTarget.innerHTML = this.promptHtml;
      return;
    }
    this.abort?.abort();
    this.abort = new AbortController();
    // Empty target + .rollup-container CSS (see _client.scss) renders the
    // shimmering "Loading…" skeleton used elsewhere in the app.
    this.resultsTarget.innerHTML = '';
    fetch(`${this.urlValue}?${params}`, { signal: this.abort.signal })
      .then((response) => (response.ok ? response.text() : Promise.reject()))
      .then((html) => { this.resultsTarget.innerHTML = html; })
      .catch((error) => {
        if (error.name === 'AbortError') return;
        this.resultsTarget.innerHTML = this.promptHtml;
      });
  }

  paramQuery() {
    const params = new URLSearchParams();
    for (const el of this.paramTargets) {
      if (!el.name || !el.value) return null;
      params.set(el.name, el.value);
    }
    return params;
  }

  // Keeps the address bar bookmarkable without a page navigation: appends the
  // first param's value as a path segment onto historyUrlValue (see the
  // data_source_with_coc_code route), or clears it back to historyUrlValue.
  updateHistoryUrl() {
    if (!this.hasHistoryUrlValue || !this.hasParamTarget) return;
    const value = this.paramTarget.value;
    const url = value ? `${this.historyUrlValue}/${encodeURIComponent(value)}` : this.historyUrlValue;
    window.history.pushState(null, '', url);
  }
}
