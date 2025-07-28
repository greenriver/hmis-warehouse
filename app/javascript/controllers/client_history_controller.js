import { Controller } from '@hotwired/stimulus';
import { TempusDominus } from '@eonasdan/tempus-dominus';

export default class extends Controller {
  static targets = [
    'calendarContainer',
    'datepickerToggle',
    'datepickerContainer',
    'projectTypeFilter',
    'projectFilter',
    'contactTypeFilter',
  ];

  static values = {
    weeks: Array,
    events: Object,
    year: Number,
    month: Number,
    minDate: String,
    maxDate: String,
  };

  connect() {
    this.filters = {};
    this.initializeFilters();
    // It's likely that AppClientHistoryCalendar is a global object from the asset pipeline.
    // If not, we may need to import it.
    this.calendar = new AppClientHistoryCalendar(
      this.weeksValue,
      this.eventsValue,
      this.calendarContainerTarget,
    );
    this.calendar.draw(this.filters, this.eventsValue);

    this.initializeDatepicker();
  }

  initializeFilters() {
    const filterNodes = [
      this.projectTypeFilterTarget,
      this.projectFilterTarget,
      this.contactTypeFilterTarget,
    ];

    filterNodes.forEach((f) => {
      const node = $(f);
      const filterName = node.data('name');
      this.filters[filterName] = node.val();
      node.select2();
      node.on('change', (e) => {
        this.filters[filterName] = node.val();
        this.calendar.draw(this.filters, this.eventsValue);
        this.updateURL(filterName, node.val());
      });
    });
  }

  initializeDatepicker() {
    let datepicker = null;

    this.datepickerToggleTarget.addEventListener('show.bs.dropdown', () => {
      if (datepicker) {
        return;
      }
      const options = {
        useCurrent: false,
        defaultDate: new Date(this.yearValue, this.monthValue - 1, 1),
        restrictions: {
          minDate: this.minDateValue ? new Date(this.minDateValue) : undefined,
          maxDate: this.maxDateValue ? new Date(this.maxDateValue) : undefined,
        },
        display: {
          viewMode: 'months',
          components: {
            decades: true,
            year: true,
            month: true,
            date: false,
            hours: false,
            minutes: false,
            seconds: false,
          },
          inline: true,
          buttons: {
            close: false,
            clear: false,
            today: false,
          },
        },
        localization: {
          format: 'yyyy-MM-dd',
        },
      };
      datepicker = new TempusDominus(this.datepickerContainerTarget, options);

      // Prevent dropdown from closing on year-related clicks
      this.datepickerContainerTarget.addEventListener('click', (e) => {
        const target = e.target;
        const isYearAction = target.matches('[data-action="selectYear"]') ||
          target.matches('[data-action="changeCalendarView"]') ||
          target.matches('[data-action="selectDecade"]') ||
          target.closest('[data-action="changeCalendarView"]') ||
          target.closest('[data-action="selectYear"]') ||
          target.closest('[data-action="selectDecade"]');

        if (isYearAction) {
          // Stop the event from bubbling up to Bootstrap dropdown
          e.stopPropagation();
        } else if (target.matches('[data-action="selectMonth"]')) {
          // Only navigate when a month is selected
          setTimeout(() => {
            const currentDate = datepicker.dates.picked[0];
            if (currentDate) {
              const month = currentDate.getMonth() + 1;
              const year = currentDate.getFullYear();
              this.navigate(month, year);
            }
          }, 100);
        }
      });
    });
  }

  navigate(month, year) {
    const url = new URL(document.location.href);
    url.searchParams.set('month', month);
    url.searchParams.set('year', year);
    url.searchParams.set('project_types', this.filters.projectTypes);
    url.searchParams.set('projects', this.filters.projects);
    url.searchParams.set('contact_types', this.filters.contactTypes);
    document.location.href = url;
  }

  updateURL(filterName, value) {
    const url = new URL(document.location.href);
    const filter_type = filterName.replace(
      /[A-Z]/g,
      (letter) => `_${letter.toLowerCase()}`,
    );
    url.searchParams.set(filter_type, value);
    window.history.pushState({}, 'FilterUpdate', url);
  }
}
