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
        icons: {
          // Mapped to your custom icon set from _icons.scss
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
      },
    };

    // Get options from the data attribute, parsed from JSON
    const elementOptions = this.element.dataset.dateOptions ? JSON.parse(this.element.dataset.dateOptions) : {};

    // Merge the default options with the options from the HTML
    const finalOptions = { ...defaultOptions, ...elementOptions };

    new TempusDominus(this.element, finalOptions);
  }
}
