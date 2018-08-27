function DropDownCellEditor () {}

// gets called once before the renderer is used
DropDownCellEditor.prototype.init = function(params) {
    var options = params.column.colDef.cellEditorParams.values;
    var select = document.createElement('select');
    // select.className = 'select2'
    var option = document.createElement("option");
    select.add(option);
    for (var i = 0; i < options.length; i++) {
      option = document.createElement("option");
      option.value = options[i];
      option.text = options[i];
      if(params.value == option.value) {
        option.selected = 'selected'
      }

      select.add(option);
    }
    this.eInput = select
};

// gets called once when grid ready to insert the element
DropDownCellEditor.prototype.getGui = function() {
    return this.eInput;
};

// focus and select can be done after the gui is attached
DropDownCellEditor.prototype.afterGuiAttached = function() {
    this.eInput.focus();
    // this.eInput.select();
};

// returns the new value after editing
DropDownCellEditor.prototype.getValue = function() {
    return this.eInput.value;
};

// any cleanup we need to be done here
DropDownCellEditor.prototype.destroy = function() {
    // but this example is simple, no cleanup, we could
    // even leave this method out as it's optional
};

// if true, then this editor will appear in a popup
DropDownCellEditor.prototype.isPopup = function() {
    return true;
};