import { Controller } from "@hotwired/stimulus"
// Some general purpose form helpers
// 1. enableOnLoad - enables previously disabled inputs on page load
// 2. submitOnChange - submits forms on input change (generally these are submitted with remote: true)

// Connects to data-controller="forms"
export default class extends Controller {
  static targets = ["enableOnLoad"]

  connect() {
    this.submissionTimeouts = new WeakMap();
    this.enableInputsOnLoad();
  }

  enableInputsOnLoad() {
    console.log('enableInputsOnLoad', this.enableOnLoadTargets);
    this.enableOnLoadTargets.forEach((wrapper) => {
      // Find the actual input element within the datepicker wrapper
      const input = wrapper.querySelector('input');
      if (input) {
        input.disabled = false;
      }
    });
  }

  submitOnChange(event) {
    const form = $(event.target).closest('form');

    if (form.length > 0) {
      const formElement = form[0];

      // Clear any existing timeout for this form
      if (this.submissionTimeouts.has(formElement)) {
        clearTimeout(this.submissionTimeouts.get(formElement));
      }

      // Set a new timeout to debounce the submission
      const timeoutId = setTimeout(() => {
        // Trigger Rails UJS form submission to respect remote: true
        form.trigger('submit');
        this.submissionTimeouts.delete(formElement);
      }, 300); // 300ms debounce

      this.submissionTimeouts.set(formElement, timeoutId);
    }
  }

  disconnect() {
    // Clear any pending timeouts
    if (this.submissionTimeouts) {
      // WeakMap doesn't have a clear method, but it will be garbage collected
      this.submissionTimeouts = null;
    }
  }
}
