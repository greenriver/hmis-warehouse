import { Controller } from '@hotwired/stimulus';

// Connects when ajax_modal_rails inserts a new modal response into the DOM
// (Stimulus's own MutationObserver picks up data-controller on AJAX-injected
// content, so this needs no inline <script> and no CSP nonce at all).
export default class extends Controller {
  static values = { size: String };

  connect() {
    const modalDialog = document.querySelector('#ajax-modal .modal-dialog');
    if (!modalDialog) return;

    modalDialog.classList.remove('modal-xxl', 'modal-xl', 'modal-lg');
    if (this.sizeValue) modalDialog.classList.add(this.sizeValue);
  }
}
