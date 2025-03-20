export class CheckboxCellEditor {
  private eGui: HTMLElement | null = null;

  init(params: { value: string | boolean }) {
    const wrapper = document.createElement('div');
    wrapper.className = 'text-center';

    const input = document.createElement('input');
    input.type = 'checkbox';
    input.value = '1';
    input.checked = params.value == '1' || params.value === true || params.value === 'true';

    wrapper.appendChild(input);
    this.eGui = wrapper;
  }

  getGui(): HTMLElement | null {
    return this.eGui;
  }

  afterGuiAttached(): void {
    // this.eGui.focus();
  }

  getValue(): string {
    if (!this.eGui) {
      return "false"; // Default value if the editor is unmounted
    }
    const checkbox = $(this.eGui).find('input[type="checkbox"]');
    return $(checkbox).is(':checked').toString();
  }

  destroy(): void {
    // Cleanup logic if needed
  }

  isPopup(): boolean {
    return false;
  }
}

export default CheckboxCellEditor;
