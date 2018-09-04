function CheckboxCellEditor () {}

// gets called once before the renderer is used
CheckboxCellEditor.prototype.init = function(params) {
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.value = 1;
    input.checked = params.value == '1';
    this.eInput = input;
};

// gets called once when grid ready to insert the element
CheckboxCellEditor.prototype.getGui = function() {
    return this.eInput;
};

// focus and select can be done after the gui is attached
CheckboxCellEditor.prototype.afterGuiAttached = function() {
    this.eInput.focus();
};

// returns the new value after editing
CheckboxCellEditor.prototype.isCancelBeforeStart = function () {
    return this.cancelBeforeStart;
};

// returns the new value after editing
CheckboxCellEditor.prototype.getValue = function() {
  console.log(this.eInput.value, this.eInput.checked);
  if(this.eInput.checked) {
    return 1
  }
  else {
    return 0
  }
  // return this.eInput.checked;
};

// any cleanup we need to be done here
CheckboxCellEditor.prototype.destroy = function() {
    // but this example is simple, no cleanup, we could
    // even leave this method out as it's optional
};

// if true, then this editor will appear in a popup
CheckboxCellEditor.prototype.isPopup = function() {
    // and we could leave this method out also, false is the default
    return false;
};