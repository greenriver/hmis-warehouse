export class DateCellRenderer {
  constructor() {
    this.eGui = null;
  }

  init(params) {
    this.eGui = this.content(params);
  }

  getGui() {
    return this.eGui;
  }

  refresh(params) {
    // Tell the grid to rebuild
    return false;
  }

  content(params) {
    const wrapper = document.createElement('div');
    wrapper.className = 'd-flex';

    const value = document.createElement('div');
    value.className = 'date';
    if (params.value) {
      const valueText = document.createTextNode(params.value);
      value.appendChild(valueText);
    }

    const icon = document.createElement('div');
    icon.className = 'icon-calendar ml-auto mt-2';

    wrapper.appendChild(value);
    wrapper.appendChild(icon);

    return wrapper;
  }

  destroy() {
    // Cleanup logic if needed
  }
}

export default DateCellRenderer;
