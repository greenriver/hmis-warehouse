function CheckboxCellEditor () {}

// gets called once before the renderer is used
CheckboxCellEditor.prototype.init = function(params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'text-center';
  var input = document.createElement('input');
  input.type = 'checkbox';
  input.value = '1';
  input.checked = params.value == '1';
  wrapper.appendChild(input);
  this.eGui = wrapper;
};

// gets called once when grid ready to insert the element
CheckboxCellEditor.prototype.getGui = function() {
  return this.eGui;
};

// focus and select can be done after the gui is attached
CheckboxCellEditor.prototype.afterGuiAttached = function() {
  // this.eGui.focus();
};

// returns the new value after editing
// CheckboxCellEditor.prototype.isCancelBeforeStart = function () {
//   console.log(this.cancelBeforeStart);
//   return this.cancelBeforeStart;
// };

// returns the new value after editing
CheckboxCellEditor.prototype.getValue = function() {
  var checkbox = $(this.eGui).find('input[type="checkbox"]');
  // the onCellValueChanged callback isn't triggered if we return false, so stringify it.
  // it means we end up saving things more than we need to, but it persists correctly
  return $(checkbox).is(':checked').toString();
};

// any cleanup we need to be done here
CheckboxCellEditor.prototype.destroy = function() {
  // console.log('destroying');
  // but this example is simple, no cleanup, we could
  // even leave this method out as it's optional
};

// if true, then this editor will appear in a popup
CheckboxCellEditor.prototype.isPopup = function() {
  // and we could leave this method out also, false is the default
  return false;
};