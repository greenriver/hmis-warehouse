/*
 * CustomFileExportsController manages the dynamic visibility of the "Custom Files"
 * section on the HMIS CSV Exports page.
 *
 * It listens for changes to the HMIS version selector and shows or hides the
 * custom files section if any custom files are available for the selected version.
 *
 * It expects the version selector element to have a `data-custom-files` attribute
 * containing a JSON object that maps HMIS versions to an object of available custom files.
 * The keys of the inner object are the display names, and the values are the filenames.
 *
 * Example of `data-custom-files`:
 * {
 *   "2026": { "Custom Genders (CustomGender.csv)": "CustomGender.csv" },
 *   "2024": {}
 * }
 *
 * It also populates a multi-select input with the available files for the selected
 * version, preserving any selections that are still valid for the new version.
 *
 * Targets:
 * - `version`: The <select> element for the HMIS version.
 * - `section`: The <div> element containing the custom files UI.
 * - `select`: The <select> element for choosing custom files.
 */
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
      const selectedFiles = JSON.parse(this.selectTarget.dataset.selectedCustomFiles || '[]');
      this.updateSelectOptions(availableFiles, selectedFiles);
    }
  }

  updateSelectOptions(files, selectedFiles) {
    const select = this.selectTarget;

    // Clear ALL existing options (including the first one)
    select.innerHTML = '';

    // Add new options - files is now a hash where keys are display titles and values are file names
    Object.entries(files).forEach(([displayTitle, fileName]) => {
      const option = new Option(displayTitle, fileName, false, selectedFiles.includes(fileName));
      select.add(option);
    });

    // Trigger Select2 update if it's initialized
    if (window.$ && window.$(select).data('select2')) {
      window.$(select).trigger('change.select2');
    }
  }
}
