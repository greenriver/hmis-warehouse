export class CheckboxCellEditor {
  constructor() {
    this.eGui = null;
  }

  init(params) {
    const wrapper = document.createElement('div');
    wrapper.className = 'text-center';

    const input = document.createElement('input');
    input.type = 'checkbox';
    input.value = '1';
    input.checked = params.value == '1' || params.value === true || params.value === 'true';

    wrapper.appendChild(input);
    this.eGui = wrapper;
  }

  getGui() {
    return this.eGui;
  }

  afterGuiAttached() {
    // this.eGui.focus();
  }

  getValue() {
    const checkbox = $(this.eGui).find('input[type="checkbox"]');
    return $(checkbox).is(':checked').toString();
  }

  destroy() {
    // Cleanup logic if needed
  }

  isPopup() {
    return false;
  }
}

export default CheckboxCellEditor;
