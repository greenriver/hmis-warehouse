import { Controller } from "@hotwired/stimulus"
import { TempusDominus, DateTime } from '@eonasdan/tempus-dominus';

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

    this.datepicker = new TempusDominus(this.element, finalOptions);

    // Override the parseInput function to handle multiple date formats using DateTime.fromString
    const originalParseInput = this.datepicker.dates.parseInput.bind(this.datepicker.dates);
    this.datepicker.dates.parseInput = (value) => {
      return this.parseFlexibleDateInput(value, originalParseInput);
    };

    // Listen for when the picker is shown to add text labels
    this.element.addEventListener('show.td', (_event) => {
      // Use a small delay to ensure the DOM is fully rendered
      setTimeout(() => {
        this.addButtonLabels();
      }, 100);
    });

    // Listen for date changes and dispatch a standard change event for submit-on-change functionality
    this.element.addEventListener('change.td', (_event) => {
      // Find the input field within the datepicker wrapper
      const inputField = this.element.querySelector('input');
      if (inputField) {
        // Dispatch a standard change event on the input field for submit-on-change functionality
        const changeEvent = new Event('change', { bubbles: true, cancelable: true });
        inputField.dispatchEvent(changeEvent);
      }
    });
  }

  disconnect() {
    if (this.datepicker && typeof this.datepicker.dispose === 'function') {
      this.datepicker.dispose();
      this.datepicker = null;
    }
  }

  parseFlexibleDateInput(value, originalParseInput) {
    // If value is null, undefined, or empty, use original parsing
    if (!value || value.toString().trim() === '') {
      return originalParseInput(value);
    }

    const rawValue = value.toString().trim();

    // Preserve any localization details supplied via data attributes so the picker
    // respects backend configuration (locale, formatting, etc.) during parsing.
    let optionsData = {};
    try {
      optionsData = this.element.dataset.dateOptions ? JSON.parse(this.element.dataset.dateOptions) : {};
    } catch (_) {
      optionsData = {};
    }

    const locale = optionsData.localization?.locale || 'en-US';
    const normalizedValue = this.normalizeMonthAliases(rawValue, locale);
    const localizationForFormat = (format) => {
      if (optionsData.localization) {
        return { ...optionsData.localization, locale, format };
      }

      return { locale, format };
    };

    // Try the original parsing first (handles the expected format)
    const tryOriginalParse = (candidate) => {
      try {
        const result = originalParseInput(candidate);
        if (result && result.isValid) {
          return result;
        }
      } catch (_) {
        // Continue to flexible parsing if original fails
      }

      return undefined;
    };

    let parsed = tryOriginalParse(rawValue);
    if (parsed) return parsed;

    if (normalizedValue !== rawValue) {
      parsed = tryOriginalParse(normalizedValue);
      if (parsed) return parsed;
    }

    // Use Tempus Dominus DateTime to parse common date formats
    // Allow both abbreviated and fully spelled-out months along with several
    // common numeric permutations so we accept the majority of user input cases.
    const formats = [
      'MMM d, yyyy',
      'MMMM d, yyyy',
      'MM/dd/yyyy',
      'M/d/yyyy',
      'MM-dd-yyyy',
      'M-d-yyyy',
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'MM/dd/yy',
      'M/d/yy',
      'MM-dd-yy',
      'M-d-yy',
    ];

    const parseCandidates = normalizedValue === rawValue ? [normalizedValue] : [normalizedValue, rawValue];
    for (const candidate of parseCandidates) {
      for (const fmt of formats) {
        try {
          const dt = DateTime.fromString(candidate, localizationForFormat(fmt));
          if (dt && DateTime.isValid(dt)) {
            return dt;
          }
        } catch (_) { }
      }
    }

    // Fallback to the browser's parser for inputs Tempus Dominus cannot handle
    // (e.g., informal month names like "Sept" that sit between MMM and MMMM).
    for (const candidate of parseCandidates) {
      const nativeDate = new Date(candidate);
      if (!Number.isNaN(nativeDate.getTime())) {
        try {
          const localization = optionsData.localization ? { ...optionsData.localization, locale } : { locale };
          return DateTime.convert(nativeDate, locale, localization);
        } catch (_) { }
      }
    }

    // If flexible parsing fails, return the original parsing result
    // This will let TempusDominus handle the error appropriately
    return originalParseInput(value);
  }

  normalizeMonthAliases(value, locale) {
    const normalizedLocale = (locale || '').toLowerCase();
    if (!normalizedLocale.startsWith('en')) {
      return value;
    }

    return value.replace(/\bsept\.?\b/gi, (match) => this.applyMatchCase(match.replace(/\./g, ''), 'Sep'));
  }

  applyMatchCase(source, target) {
    if (source === source.toUpperCase()) return target.toUpperCase();
    if (source === source.toLowerCase()) return target.toLowerCase();
    return target[0].toUpperCase() + target.slice(1);
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
