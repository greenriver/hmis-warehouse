// Renderer
function CheckboxCellRenderer () {}

// gets called once before the renderer is used
CheckboxCellRenderer.prototype.init = function(params) {
  // this.refresh(params);
  this.eGui = this.content(params);
};

// gets called once when grid ready to insert the element
CheckboxCellRenderer.prototype.getGui = function() {
  return this.eGui;
};

// gets called whenever the user gets the cell to refresh
CheckboxCellRenderer.prototype.refresh = function(params) {
  // Force the grid to re-initialize this
  return false;
};

CheckboxCellRenderer.prototype.content = function (params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'text-center'
  var checkmark = document.createElement('span');
  if (params.value != 'false' && params.value) {
    checkmark.className = 'icon-checkmark o-color--positive';
  }
  else {
    // checkmark.className = 'icon-cross o-color--danger';
  }
  wrapper.appendChild(checkmark);
  return wrapper;
}

// gets called when the cell is removed from the grid
CheckboxCellRenderer.prototype.destroy = function() {
  // do cleanup, remove event listener from button

};
