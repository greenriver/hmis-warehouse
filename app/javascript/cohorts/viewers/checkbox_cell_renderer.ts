export class CheckboxCellRenderer {
  private eGui: HTMLElement | null = null;

  init(params: ICellRendererParams): void {
    this.eGui = this.content(params);
  }

  getGui(): HTMLElement | null {
    return this.eGui;
  }

  refresh(params: ICellRendererParams): boolean {
    // Force the grid to re-initialize this
    return false;
  }

  content(params: ICellRendererParams): HTMLElement {
    const wrapper = document.createElement('div');
    wrapper.className = 'text-center';
    const checkmark = document.createElement('span');
    if (params.value !== 'false' && params.value) {
      checkmark.className = 'icon-checkmark o-color--positive';
    }
    wrapper.appendChild(checkmark);
    return wrapper;
  }

  destroy(): void {
    // Cleanup logic if needed
  }
}

export default CheckboxCellRenderer;
