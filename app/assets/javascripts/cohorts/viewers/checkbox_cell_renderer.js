// Renderer
function CheckboxCellRenderer () {}

// gets called once before the renderer is used
CheckboxCellRenderer.prototype.init = function(params) {
  this.refresh(params);
};

// gets called once when grid ready to insert the element
CheckboxCellRenderer.prototype.getGui = function() {
  return this.eGui;
};

// gets called whenever the user gets the cell to refresh
CheckboxCellRenderer.prototype.refresh = function(params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'text-center'
  var checkmark =  document.createElement('span');
  if (params.value) {
    checkmark.className = 'icon-checkmark o-color--positive';
  }
  else {
    // checkmark.className = 'icon-cross o-color--danger';
  }
  wrapper.appendChild(checkmark);
  this.eGui = wrapper;
  return true;
};

// gets called when the cell is removed from the grid
CheckboxCellRenderer.prototype.destroy = function() {
  // do cleanup, remove event listener from button

};
