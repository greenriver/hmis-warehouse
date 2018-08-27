// function CheckboxCellRenderer() {}

// CheckboxCellRenderer.prototype.init = function (params) {
//   // Create the DOM element to display
//   this.input = document.createElement('input');
//   this.input.type = 'checkbox';
//   this.input.checked = params.value;
//   this.refresh(params)
// };

// CheckboxCellRenderer.prototype.refresh = function(params) {
//   this.input = document.createElement('input');
//   this.input.type = 'checkbox';
//   this.input.checked = params.value;
// }

// CheckboxCellRenderer.prototype.getGui = function () {
//   return this.input;
// };


// Renderer
function CheckboxCellRenderer () {}

// gets called once before the renderer is used
CheckboxCellRenderer.prototype.init = function(params) {
  this.eInput = document.createElement('input');
  this.eInput.type = 'checkbox';
  this.eInput.checked = params.value;
  this.refresh(params);
};

// gets called once when grid ready to insert the element
CheckboxCellRenderer.prototype.getGui = function() {
  return this.eInput;
};

// gets called whenever the user gets the cell to refresh
CheckboxCellRenderer.prototype.refresh = function(params) {
  // console.log(params.getValue());
  // set value into cell again
  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true;
};

// gets called when the cell is removed from the grid
CheckboxCellRenderer.prototype.destroy = function() {
  // do cleanup, remove event listener from button
  this.eInput.removeEventListener('click', this.eventListener);
};
