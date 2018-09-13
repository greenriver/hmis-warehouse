//Date Editor
function DateCellEditor () {}

// gets called once before the renderer is used
DateCellEditor.prototype.init = function(params) {
  // create the cell
  this.eInput = document.createElement('input');
  this.eInput.value = params.value;

  // https://jqueryui.com/datepicker/
  $(this.eInput).datepicker({
    dateFormat: "dd/mm/yy",
    changeMonth: true,
    changeYear: true,
    autoclose: true
  }).on('hide', function(e) {
    params.stopEditing();
  });
};

// gets called once when grid ready to insert the element
DateCellEditor.prototype.getGui = function() {
  return this.eInput;
};

// focus and select can be done after the gui is attached
DateCellEditor.prototype.afterGuiAttached = function() {
  this.eInput.focus();
  this.eInput.select();
};

// returns the new value after editing
DateCellEditor.prototype.isCancelBeforeStart = function () {
    return this.cancelBeforeStart;
};

// returns the new value after editing
DateCellEditor.prototype.getValue = function() {
  return this.eInput.value;
};

// any cleanup we need to be done here
DateCellEditor.prototype.destroy = function() {
  // but this example is simple, no cleanup, we could
  // even leave this method out as it's optional
};

// if true, then this editor will appear in a popup
DateCellEditor.prototype.isPopup = function() {
  // and we could leave this method out also, false is the default
  return false;
};