export class DropdownCellEditor {
  private params: ICellEditorParams | null = null;
  private selectedValue: string | null = null;
  private originalSelectedValue: string | null = null;
  private focusAfterAttached: boolean = false;
  private available_options: string[] = [];
  private eGui: HTMLElement | null = null;

  init(params: ICellEditorParams): void {
    this.params = params;
    this.selectedValue = params.value;
    this.originalSelectedValue = params.value;
    this.focusAfterAttached = params.cellStartedEdit;
    this.available_options = params.values || [];

    if (this.available_options.length === 0) {
      return;
    }

    this.eGui = this.getUI();
    this.makeClickable();
  }

  getUI(): HTMLElement {
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

  makeClickable(): void {
    const gui = this.getGui();
    if (!gui) return;

    $(gui).on('click', 'li', (e) => {
      e.preventDefault();
      const value = $(e.currentTarget).text();
      this.setSelectedValue(value);
      this.params?.stopEditing();
    });
  }

  setSelectedValue(value: string): void {
    if (this.selectedValue !== value) {
      const index = this.available_options.indexOf(value);
      if (index >= 0) {
        this.selectedValue = value;
      }
    }
  }

  getGui(): HTMLElement | null {
    return this.eGui;
  }

  afterGuiAttached(): void {
    // this.eGui?.focus();
  }

  getValue(): string | null {
    return this.selectedValue;
  }

  destroy(): void { }

  isPopup(): boolean {
    return true;
  }
}

export default DropdownCellEditor;
