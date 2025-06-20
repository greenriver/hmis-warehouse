import { Controller } from '@hotwired/stimulus';
// Do NOT import a private jQuery. Use the global one from Sprockets.
const $ = window.jQuery;
import MapWithShapes from '../maps/map_with_shapes';

export default class extends Controller {
  static values = {
    shapes: Object,
  };

  static targets = [
    'form',
    'submitButton',
    'prompt',
    'loading',
    'errorContainer',
    'results',
    'coc1Input',
    'title',
    'subtitle',
    'map',
  ];

  connect() {
    console.log('shapesValue', this.shapesValue);
    this.map = new MapWithShapes({
      elementId: this.mapTarget.id,
      shapes: this.shapesValue,
    });

    // Use a delegated event listener on the document to reliably catch the change event
    // from the select2 instance, avoiding race conditions on initialization.
    this.boundHandleChange = this.handlePotentialChange.bind(this);
    $(document).on('change', this.boundHandleChange);

    this.postForm();
  }

  disconnect() {
    $(document).off('change', this.boundHandleChange);
  }

  handlePotentialChange(evt) {
    if (evt.target === this.coc1InputTarget) {
      this.handleCoc1Change();
    }
  }

  handleCoc1Change() {
    const value = this.coc1InputTarget.value;
    this.submitButtonTarget.disabled = !value;
    this.promptTarget.classList.toggle('d-none', !!value);
  }

  postForm(evt) {
    if (evt) {
      evt.preventDefault();
    }

    if (!this.formTarget.checkValidity()) {
      return;
    }

    this.indicateLoading(true);

    const formData = $(this.formTarget).serialize();
    const newUrl = `${window.location.href.split('?')[0]}?${formData}`;
    window.history.pushState({}, 'FormSubmit', newUrl);

    $.ajax({
      type: 'GET',
      url: this.formTarget.action,
      data: formData,
    })
      .done((data) => {
        this.indicateLoading(false, data.error);
        this.displayResults(data);
      })
      .fail(() => {
        this.indicateLoading(false);
        alert('An error occurred while processing your request');
      });
  }

  indicateLoading(loading, error = null) {
    this.loadingTarget.classList.toggle('d-none', !loading);
    this.submitButtonTarget.disabled = loading;

    if (loading) {
      this.resultsTarget.style.opacity = 0.4;
      this.resultsTarget.style.pointerEvents = 'none';
    } else {
      this.resultsTarget.style.opacity = 1;
      this.resultsTarget.style.pointerEvents = 'all';
    }

    this.errorContainerTarget.textContent = '';
    this.errorContainerTarget.classList.add('hide');
    if (error) {
      this.errorContainerTarget.textContent = error;
      this.errorContainerTarget.classList.remove('hide');
    }
  }

  displayResults(data) {
    if (data.title) {
      this.titleTarget.innerHTML = data.title;
      this.titleTarget.classList.remove('d-none');
    }
    this.subtitleTarget.innerHTML = data.subtitle;
    this.resultsTarget.innerHTML = data.html;
    this.map.updateShapes({
      shapes: data.map,
      primaryId: data.coc1_id,
      secondaryId: data.coc2_id,
    });
  }
}
