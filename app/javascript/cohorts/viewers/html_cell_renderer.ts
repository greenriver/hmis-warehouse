export class HtmlCellRenderer {
  constructor() {
    this.params = null;
    this.row = null;
    this.eGui = null;
  }

  init(params) {
    this.params = params;
    this.row = params.data[params.colDef.field];
    this.refresh(params);
  }

  getGui() {
    return this.eGui;
  }

  refresh(params) {
    const wrapper = document.createElement('div');
    wrapper.className = '';
    wrapper.innerHTML = this.params.value;
    if (this.row.comments) {
      wrapper.setAttribute('data-toggle', 'tooltip');
      wrapper.setAttribute('data-title', this.row.comments);
      wrapper.setAttribute('data-placement', 'left');
      wrapper.setAttribute('data-container', 'body');
      wrapper.setAttribute('data-boundary', 'viewport');
      $(wrapper).tooltip();
    }
    this.eGui = wrapper;
    return true;
  }

  destroy() {
    // Cleanup logic if needed
  }
}

export default HtmlCellRenderer;
