import { Controller } from "@hotwired/stimulus"
import { TempusDominus } from '@eonasdan/tempus-dominus';

// Connects to data-controller="datepicker"
export default class extends Controller {
  connect() {
    // Default options, including our custom icons
    const defaultOptions = {
      display: {
        icons: {
          // Mapped to your custom icon set from _icons.scss
          previous: 'icon-angle-left',
          next: 'icon-angle-right',
          up: 'icon-angle-up',
          down: 'icon-angle-down',
          date: 'icon-calendar',
          time: 'icon-clock-o',
          clear: 'icon-cross',
          close: 'icon-cross'
        },
        theme: 'light' // Or 'dark' if you prefer
      }
    };

    // Get options from the data attribute, parsed from JSON
    const elementOptions = this.element.dataset.dateOptions ? JSON.parse(this.element.dataset.dateOptions) : {};

    // Merge the default options with the options from the HTML
    const finalOptions = { ...defaultOptions, ...elementOptions };

    new TempusDominus(this.element, finalOptions);
  }
}
