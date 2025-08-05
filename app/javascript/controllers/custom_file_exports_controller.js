import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['version', 'section', 'select'];
  }

  connect() {
    this.toggleVisibility();

    // Listen for Select2 events on the version target
    if (this.hasVersionTarget) {
      const $versionSelect = window.$(this.versionTarget);
      $versionSelect.on('select2:select select2:unselect select2:close', () => {
        this.toggleVisibility();
      });
    }
  }

  toggleVisibility() {
    // The hashed HMIS export uses the same page, but doesn't include custom files
    if (!this.hasVersionTarget || !this.hasSectionTarget) {
      return;
    }

    const version = this.versionTarget.value;
    const customFilesData = JSON.parse(this.versionTarget.dataset.customFiles || '{}');
    const availableFiles = customFilesData[version] || {};

    // Show/hide the entire section based on whether files are available
    const showSection = Object.keys(availableFiles).length > 0;

    this.sectionTargets.forEach((section) => {
      section.style.display = showSection ? '' : 'none';
    });

    // Update the select options
    if (this.hasSelectTarget && showSection) {
      this.updateSelectOptions(availableFiles);
    }
  }

  updateSelectOptions(files) {
    const select = this.selectTarget;

    // Clear ALL existing options (including the first one)
    select.innerHTML = '';

    // Add new options - files is now a hash where keys are display titles and values are file names
    Object.entries(files).forEach(([displayTitle, fileName]) => {
      const option = new Option(displayTitle, fileName);
      select.add(option);
    });

    // Trigger Select2 update if it's initialized
    if (window.$ && window.$(select).data('select2')) {
      window.$(select).trigger('change.select2');
    }
  }
}
