// Date Editor
export class DateCellEditor {
  init(params) {
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
    }).on('hide', function (e) {
      params.stopEditing();
    });
  }

  getGui() {
    return this.eInput;
  }

  afterGuiAttached() {
    this.eInput.focus();
    this.eInput.select();
  }

  isCancelBeforeStart() {
    return this.cancelBeforeStart;
  }

  getValue() {
    return this.eInput.value;
  }

  destroy() {
  }

  isPopup() {
    // and we could leave this method out also, false is the default
    return false;
  }
}

export default DateCellEditor;
