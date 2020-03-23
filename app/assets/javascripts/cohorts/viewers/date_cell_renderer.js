function DateCellRenderer () {}

// gets called once before the renderer is used
DateCellRenderer.prototype.init = function(params) {
  this.eGui = this.content(params);
};

// gets called once when grid ready to insert the element
DateCellRenderer.prototype.getGui = function() {
  return this.eGui;
};

// gets called whenever the user gets the cell to refresh
DateCellRenderer.prototype.refresh = function(params) {
  // tell the grid to rebuild
  return false;
};

DateCellRenderer.prototype.content = function (params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'd-flex';
  var value = document.createElement('div');
  value.className = 'date';
  if (params.value) {
    var value_text = document.createTextNode(params.value);
    value.appendChild(value_text);
  }
  var icon = document.createElement('div');
  icon.className = 'icon-calendar ml-auto mt-2';
  wrapper.appendChild(value);
  wrapper.appendChild(icon);
  return wrapper;
}

// gets called when the cell is removed from the grid
DateCellRenderer.prototype.destroy = function() {

};
