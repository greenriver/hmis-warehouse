import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['version', 'section', 'select'];
  }

  connect() {
    console.log('CustomFiles controller connected');
    this.toggleVisibility();
  }

  toggleVisibility() {
    console.log('toggleVisibility called');
    console.log('hasVersionTarget:', this.hasVersionTarget);
    console.log('hasSectionTargets:', this.hasSectionTargets);
    
    if (!this.hasVersionTarget || !this.hasSectionTargets) {
      console.log('Returning early - missing targets');
      return;
    }
    
    const version = this.versionTarget.value;
    const customFilesData = JSON.parse(this.versionTarget.dataset.customFiles || '{}');
    const availableFiles = customFilesData[version] || [];
    
    console.log('Version:', version, 'Available files:', availableFiles);
    
    // Show/hide the entire section based on whether files are available
    const showSection = availableFiles.length > 0;
    
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
    
    // Clear existing options except the first (placeholder)
    while (select.options.length > 1) {
      select.remove(1);
    }
    
    // Add new options
    files.forEach(file => {
      const option = new Option(file, file);
      select.add(option);
    });
    
    // Trigger Select2 update if it's initialized
    if (window.$ && window.$(select).data('select2')) {
      window.$(select).trigger('change.select2');
    }
  }
}