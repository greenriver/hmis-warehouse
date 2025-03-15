export class CheckboxCellRenderer {
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
    // Force the grid to re-initialize this
    return false;
  }

  content(params) {
    const wrapper = document.createElement('div');
    wrapper.className = 'text-center';
    const checkmark = document.createElement('span');
    if (params.value != 'false' && params.value) {
      checkmark.className = 'icon-checkmark o-color--positive';
    }
    wrapper.appendChild(checkmark);
    return wrapper;
  }

  destroy() {
    // Cleanup logic if needed
  }
}

export default CheckboxCellRenderer;
