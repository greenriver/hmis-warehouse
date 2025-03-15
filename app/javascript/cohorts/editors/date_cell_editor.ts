// Date Editor
import { ICellEditorParams } from 'ag-grid-community';

export class DateCellEditor {
  private eInput: HTMLInputElement;
  private cancelBeforeStart: boolean = false;

  init(params: ICellEditorParams): void {
    // create the cell
    this.eInput = document.createElement('input');
    this.eInput.value = params.value;

    // https://jqueryui.com/datepicker/
    $(this.eInput).datepicker({
      dateFormat: 'dd/mm/yyyy',
      changeMonth: true,
      changeYear: true,
      autoclose: true,
      clearBtn: true
      // eslint-disable-next-line no-unused-vars
    }).on('hide', (e) => {
      params.stopEditing();
    });
  }

  getGui(): HTMLElement {
    return this.eInput;
  }

  afterGuiAttached(): void {
    this.eInput.focus();
    this.eInput.select();
  }

  isCancelBeforeStart(): boolean {
    return this.cancelBeforeStart;
  }

  getValue(): string {
    return this.eInput.value;
  }

  destroy(): void {
  }

  isPopup(): boolean {
    // and we could leave this method out also, false is the default
    return false;
  }
}

export default DateCellEditor;
