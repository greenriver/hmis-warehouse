import { Controller } from "@hotwired/stimulus"
import { TempusDominus, DateTime } from '@eonasdan/tempus-dominus';

// Connects to data-controller="datepicker"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    const dropdownMenu = this.element.closest('.dropdown-menu');
    // When the input lives in a Bootstrap modal (e.g. AjaxModal #ajax-modal), use the
    // modal shell as the widget container so overflow clipping matches the dialog.
    const modal = this.element.closest('.modal');
    const modalContent =
      modal && (modal.querySelector('.modal-content') || modal);

    const container = dropdownMenu ? dropdownMenu : modalContent;  
    const containerOptions = container ? { container: container } : {};

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

    // Merge the default options with the options from the HTML. `display` merges one level deeper so
    // an input can enable clock components without restating the icons and buttons.
    const finalOptions = {
      ...defaultOptions,
      ...elementOptions,
      display: {
        ...defaultOptions.display,
        ...(elementOptions.display || {}),
        components: {
          ...defaultOptions.display.components,
          ...(elementOptions.display?.components || {}),
        },
      },
    };

    // Only the calendar button opens the popup. Tempus Dominus defaults the toggle to the whole
    // wrapper and moves focus into the calendar grid on open, so clicking the text box to type a
    // date sent the keystrokes to the grid instead.
    if (this.element.tagName !== 'INPUT' && !this.element.dataset.tdTargetToggle && this.element.querySelector('button')) {
      this.element.dataset.tdTargetToggle = 'button';
    }

    // Name the calendar button after its field ("Choose Start Date"). Tempus Dominus renames the
    // button to "<toggleAriaLabel>, <picked date>" on every change, so the name goes through that
    // option rather than only onto the button.
    const fieldLabel = this.fieldLabel();
    this.toggleName = fieldLabel ? `Choose ${fieldLabel}` : 'Choose date';
    finalOptions.localization = { ...finalOptions.localization, toggleAriaLabel: this.toggleName };

    this.datepicker = new TempusDominus(this.element, finalOptions);

    // Override the parseInput function to handle multiple date formats using DateTime.fromString
    const originalParseInput = this.datepicker.dates.parseInput.bind(this.datepicker.dates);
    this.datepicker.dates.parseInput = (value) => {
      return this.parseFlexibleDateInput(value, originalParseInput);
    };

    this.labelToggleButton();

    // Listen for when the picker is shown to add text labels
    this.element.addEventListener('show.td', (_event) => {
      this.toggleButton?.setAttribute('aria-expanded', 'true');
      // Use a small delay to ensure the DOM is fully rendered
      setTimeout(() => {
        this.addButtonLabels();
        this.labelPopup();
      }, 100);
    });

    this.element.addEventListener('hide.td', (_event) => {
      this.toggleButton?.setAttribute('aria-expanded', 'false');
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
    const input = this.element.tagName === 'INPUT' ? this.element : this.element.querySelector('input');

    // If value is null, undefined, or empty, use original parsing
    if (!value || value.toString().trim() === '') {
      this.markInputValidity(input, true);
      return originalParseInput(value);
    }

    const rawValue = value.toString().trim();
    const localization = this.datepicker.optionsStore?.options?.localization || {};
    const locale = localization.locale || 'en-US';
    const normalizedValue = this.normalizeMonthAliases(rawValue, locale);

    // Tempus Dominus parses leniently: it skips text it cannot match and lets Date roll overflow
    // forward, so "Mar 15 2024" read against "MMM d, yyyy" came back as Mar 20, 2025 and "2/30/2024"
    // as Mar 1. Accept a parse only when formatting the result with the same pattern gives back
    // what was typed.
    const parseStrict = (candidate, format) => {
      try {
        const dt = DateTime.fromString(candidate, { ...localization, locale, format });
        if (dt && DateTime.isValid(dt) && this.sameDateText(dt.format(format), candidate)) return dt;
      } catch (_) {
        // fromString throws on some unparseable input; try the next format
      }
      return undefined;
    };

    // The configured format comes first so a datetime input keeps its time. The fallbacks are
    // date-only and drop the time.
    const formats = [
      localization.format,
      'MMM d, yyyy',
      'MMM d yyyy',
      'MMMM d, yyyy',
      'MMMM d yyyy',
      'd MMM yyyy',
      'd MMMM yyyy',
      'M/d/yyyy',
      'M-d-yyyy',
      'yyyy-M-d',
      'yyyy/M/d',
      'M/d/yy',
      'M-d-yy',
    ].filter(Boolean);

    const candidates = normalizedValue === rawValue ? [rawValue] : [normalizedValue, rawValue];
    for (const candidate of candidates) {
      for (const format of formats) {
        const parsed = parseStrict(candidate, format);
        if (parsed) {
          this.markInputValidity(input, true);
          return parsed;
        }
      }
    }

    // Leave the typed text in place and flag it, rather than guessing at a date. Returning
    // undefined tells Tempus Dominus not to change the selected date.
    this.markInputValidity(input, false);
    return undefined;
  }

  // Compare formatted and typed dates ignoring case, commas, extra spaces, and leading zeros, so
  // "03/05/2024" matches the M/d/yyyy pattern and "sep 3 2023" matches "Sep 3, 2023".
  sameDateText(formatted, typed) {
    const normalize = (text) => text.toLowerCase().replace(/[\s,]+/g, ' ').replace(/\b0+(?=\d)/g, '').trim();
    return normalize(formatted) === normalize(typed);
  }

  markInputValidity(input, valid) {
    if (!input) return;

    input.classList.toggle('is-invalid', !valid);
    input.setCustomValidity(valid ? '' : 'Enter a date like Jan 31, 2025 or 1/31/2025');

    // Screen readers get the error through aria-invalid and aria-describedby; any description the
    // input already had is kept.
    let feedback = this.element.querySelector('.datepicker-invalid-feedback');
    const describedBy = (input.getAttribute('aria-describedby') || '').split(' ').filter((id) => id && id !== feedback?.id);
    if (valid) {
      feedback?.remove();
      input.removeAttribute('aria-invalid');
    } else {
      if (!feedback) {
        feedback = document.createElement('div');
        feedback.className = 'invalid-feedback datepicker-invalid-feedback';
        feedback.id = `${input.id || 'datepicker'}-error-${Math.random().toString(36).slice(2, 8)}`;
        feedback.textContent = input.validationMessage;
        this.element.appendChild(feedback);
      }
      input.setAttribute('aria-invalid', 'true');
      describedBy.push(feedback.id);
    }
    if (describedBy.length) {
      input.setAttribute('aria-describedby', describedBy.join(' '));
    } else {
      input.removeAttribute('aria-describedby');
    }
  }

  // The field's label without the required-field asterisk, e.g. "Start Date"
  fieldLabel() {
    const input = this.element.tagName === 'INPUT' ? this.element : this.element.querySelector('input');
    const text = input?.labels?.[0]?.textContent || input?.getAttribute('aria-label') || '';
    return text.replace(/\*/g, '').replace(/\s+/g, ' ').trim();
  }

  // Name the calendar button after its field ("Choose Start Date") so Start and End don't both read
  // "Open Date Picker", and so hand-built buttons with only an icon get a name at all.
  labelToggleButton() {
    const toggle = this.datepicker.optionsStore?.toggle;
    if (!toggle || toggle === this.element || toggle.tagName !== 'BUTTON') return;

    this.toggleButton = toggle;
    toggle.setAttribute('aria-label', this.toggleName);
    toggle.setAttribute('aria-haspopup', 'dialog');
    toggle.setAttribute('aria-expanded', 'false');
  }

  // Tempus Dominus gives the popup role="widget", which isn't an ARIA role, and no name. Its
  // previous/next and footer controls are divs, so they also need a button role.
  labelPopup() {
    const picker = this.datepicker?.display?.widget;
    if (!picker) return;

    picker.setAttribute('role', 'dialog');
    picker.setAttribute('aria-label', this.toggleName);
    picker.querySelectorAll('[data-action="previous"], [data-action="next"], [data-action="changeCalendarView"], [data-action="today"], [data-action="clear"], [data-action="close"]').forEach((control) => {
      control.setAttribute('role', 'button');
      // The month/year switch keeps its visible text ("January 2025") as its name
      if (control.dataset.action === 'changeCalendarView') return;
      if (!control.getAttribute('aria-label') && control.getAttribute('title')) {
        control.setAttribute('aria-label', control.getAttribute('title'));
      }
    });
  }

  normalizeMonthAliases(value, locale) {
    const normalizedLocale = (locale || '').toLowerCase();
    if (!normalizedLocale.startsWith('en')) {
      return value;
    }

    // Tempus Dominus matches month names case-sensitively, so "mar 15 2024" and "SEPT. 3" need
    // "Mar 15 2024" and "Sep 3"
    return value
      .replace(/\b([a-z]{3,})\./gi, '$1')
      .replace(/\bsept\b/gi, 'Sep')
      .replace(/\b[a-z]+\b/gi, (word) => word[0].toUpperCase() + word.slice(1).toLowerCase());
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
