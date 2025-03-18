import { ICellRendererParams } from 'ag-grid-community';

export class DateCellRenderer {
  private eGui: HTMLElement | null;

  constructor() {
    this.eGui = null;
  }

  init(params: ICellRendererParams): void {
    this.eGui = this.content(params);
  }

  getGui(): HTMLElement | null {
    return this.eGui;
  }

  refresh(params: ICellRendererParams): boolean {
    // Tell the grid to rebuild
    return false;
  }

  content(params: ICellRendererParams): HTMLElement {
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

  destroy(): void {
    // Cleanup logic if needed
  }
}

export default DateCellRenderer;
