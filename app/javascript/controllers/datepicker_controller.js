import { Controller } from "@hotwired/stimulus"
import { TempusDominus } from '@eonasdan/tempus-dominus';

// Connects to data-controller="datepicker"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    const dropdownMenu = this.element.closest('.dropdown-menu');
    const containerOptions = dropdownMenu ? { container: dropdownMenu } : {};

    // Default options, including our custom icons
    const defaultOptions = {
      ...containerOptions,
      display: {
        // Mapped to your custom icon set from _icons.scss
        icons: {
          previous: 'icon-angle-left',
          next: 'icon-angle-right',
          up: 'icon-angle-up',
          down: 'icon-angle-down',
          date: 'icon-calendar',
          time: 'icon-clock-o',
          clear: 'icon-checkbox-unchecked',
          close: 'icon-cross',
          today: 'icon-calendar',
        },
        theme: 'light', // Or 'dark' if you prefer
        buttons: {
          today: true,
          clear: true,
          close: true,
        },
        components: {
          calendar: true,
          date: true,
          month: true,
          year: true,
          decades: true,
          clock: false,
          hours: false,
          minutes: false,
          seconds: false,
        },
      },
      localization: {
        format: 'MMM d, yyyy',
        dayViewHeaderFormat: { month: 'long', year: 'numeric' },
      },
    };

    // Get options from the data attribute, parsed from JSON
    const elementOptions = this.element.dataset.dateOptions ? JSON.parse(this.element.dataset.dateOptions) : {};

    // Merge the default options with the options from the HTML
    const finalOptions = { ...defaultOptions, ...elementOptions };

    const datepicker = new TempusDominus(this.element, finalOptions);

    // Listen for when the picker is shown to add text labels
    this.element.addEventListener('show.td', (_event) => {
      // Use a small delay to ensure the DOM is fully rendered
      setTimeout(() => {
        this.addButtonLabels();
      }, 100);
    });
  }

  addButtonLabels() {
    // Find the currently visible picker widget
    const picker = document.querySelector('.tempus-dominus-widget.show');
    if (!picker) return;

    const todayBtn = picker.querySelector('[data-action="today"]');
    const clearBtn = picker.querySelector('[data-action="clear"]');
    const closeBtn = picker.querySelector('[data-action="close"]');

    this.formatButton(todayBtn);
    this.formatButton(clearBtn);
    this.formatButton(closeBtn);
  }

  formatButton(button) {
    if (!button || button.querySelector('.button-label')) return; // Skip if already formatted

    const title = button.getAttribute('title');
    if (!title) return;

    const icon = button.querySelector('i');
    if (!icon) return;

    // Clear existing content and rebuild structure
    button.innerHTML = '';

    // Add flexbox styling for vertical centering
    button.style.display = 'flex';
    button.style.flexDirection = 'column';
    button.style.alignItems = 'center';
    button.style.justifyContent = 'center';
    button.style.gap = '4px';

    // Re-add the icon
    button.appendChild(icon);

    // Create and add the label
    const label = document.createElement('small');
    label.className = 'button-label';
    label.textContent = title;
    label.style.fontSize = '0.75em';
    label.style.lineHeight = '1';
    button.appendChild(label);

    // Update aria-label to match the title
    button.setAttribute('aria-label', title);
  }
}
