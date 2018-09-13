function DropdownCellEditor () {}


// gets called once before the renderer is used
DropdownCellEditor.prototype.init = function(params) {
  this.params = params;
  this.selectedValue = params.value;
  this.originalSelectedValue = params.value;
  this.focusAfterAttached = params.cellStartedEdit;

  this.available_options = params.values;
  if(this.available_options.length == 0) {
    return;
  }
  this.eGui = this.getUI();
  this.makeClickable();
};

DropdownCellEditor.prototype.getUI = function() {
  var wrapper = document.createElement('div');
  wrapper.className = 'dropdown-wrapper';
  var list = document.createElement('ol');
  list.className = 'dropdown-list'
  var list_item = document.createElement('li');
  $(list_item).text(this.selectedValue);
  if(this.selectedValue) {
    list.appendChild(list_item);
  }
  for(var i = 0; i < this.available_options.length; i++) {
    list_item = document.createElement('li');
    $(list_item).text(this.available_options[i]);
    list.appendChild(list_item);
  }
  wrapper.appendChild(list);
  return wrapper;
};

DropdownCellEditor.prototype.makeClickable = function() {
  var that = this;
  $(this.getGui()).on('click', 'li', function(e) {
    e.preventDefault();
    var value = $(e.currentTarget).text();
    that.setSelectedValue(value);
    that.params.stopEditing();
  });
};

DropdownCellEditor.prototype.setSelectedValue = function (value) {
  if (this.selectedValue === value) {
    return;
  }
  var index = this.available_options.indexOf(value);
  if (index >= 0) {
    this.selectedValue = value;
  }
};

// gets called once when grid ready to insert the element
DropdownCellEditor.prototype.getGui = function() {
  return this.eGui;
};

// focus and select can be done after the gui is attached
DropdownCellEditor.prototype.afterGuiAttached = function() {
  // this.eGui.focus();
};

// returns the new value after editing
DropdownCellEditor.prototype.getValue = function() {
  return this.selectedValue;
};

DropdownCellEditor.prototype.destroy = function() {

}

// if true, then this editor will appear in a popup
DropdownCellEditor.prototype.isPopup = function() {
  return true;
};