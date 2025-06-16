export class HtmlCellRenderer {
  private params: ICellRendererParams | null = null;
  private row: any | null = null;
  private eGui: HTMLElement | null = null;

  init(params: ICellRendererParams): void {
    this.params = params;
    this.row = params.data[params.colDef.field];
    this.refresh(params);
  }

  getGui(): HTMLElement | null {
    return this.eGui;
  }

  refresh(params: ICellRendererParams): boolean {
    const wrapper = document.createElement('div');
    wrapper.className = '';
    wrapper.innerHTML = this.params?.value || '';
    if (this.row?.comments) {
      wrapper.setAttribute('data-bs-toggle', 'tooltip');
      wrapper.setAttribute('data-title', this.row.comments);
      wrapper.setAttribute('data-placement', 'left');
      wrapper.setAttribute('data-container', 'body');
      wrapper.setAttribute('data-boundary', 'viewport');
      $(wrapper).tooltip();
    }
    this.eGui = wrapper;
    return true;
  }

  destroy(): void {
    // Cleanup logic if needed
  }
}

export default HtmlCellRenderer;
