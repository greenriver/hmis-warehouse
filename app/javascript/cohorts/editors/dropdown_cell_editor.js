export class DropdownCellEditor {
  constructor() {
    this.params = null;
    this.selectedValue = null;
    this.originalSelectedValue = null;
    this.focusAfterAttached = false;
    this.available_options = [];
    this.eGui = null;
  }

  init(params) {
    this.params = params;
    this.selectedValue = params.value;
    this.originalSelectedValue = params.value;
    this.focusAfterAttached = params.cellStartedEdit;
    this.available_options = params.values;

    if (this.available_options.length === 0) {
      return;
    }

    this.eGui = this.getUI();
    this.makeClickable();
  }

  getUI() {
    const wrapper = document.createElement('div');
    wrapper.className = 'dropdown-wrapper';
    const list = document.createElement('ol');
    list.className = 'dropdown-list';

    if (this.selectedValue) {
      const selectedItem = document.createElement('li');
      $(selectedItem).text(this.selectedValue);
      list.appendChild(selectedItem);
    }

    for (const option of this.available_options) {
      const listItem = document.createElement('li');
      $(listItem).text(option);
      list.appendChild(listItem);
    }

    wrapper.appendChild(list);
    return wrapper;
  }

  makeClickable() {
    $(this.getGui()).on('click', 'li', (e) => {
      e.preventDefault();
      const value = $(e.currentTarget).text();
      this.setSelectedValue(value);
      this.params.stopEditing();
    });
  }

  setSelectedValue(value) {
    if (this.selectedValue !== value) {
      const index = this.available_options.indexOf(value);
      if (index >= 0) {
        this.selectedValue = value;
      }
    }
  }

  getGui() {
    return this.eGui;
  }

  afterGuiAttached() {
    // this.eGui.focus();
  }

  getValue() {
    return this.selectedValue;
  }

  destroy() { }

  isPopup() {
    return true;
  }
}

export default DropdownCellEditor;
