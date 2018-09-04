function DateCellRenderer () {}

// gets called once before the renderer is used
DateCellRenderer.prototype.init = function(params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'd-flex';
  var value = document.createElement('div');
  value.className = 'date';
  if(params.value) {
    var value_text = document.createTextNode(params.value);
    value.appendChild(value_text);
  }
  var icon = document.createElement('div');
  icon.className = 'icon-calendar ml-auto mt-2';
  wrapper.appendChild(value);
  wrapper.appendChild(icon);
  this.eGui = wrapper;
};

// gets called once when grid ready to insert the element
DateCellRenderer.prototype.getGui = function() {
  return this.eGui;
};

// gets called whenever the user gets the cell to refresh
DateCellRenderer.prototype.refresh = function(params) {
  // set value into cell again
  console.log('refresh', params);

  // this.eValue.innerHTML = params.valueFormatted ? params.valueFormatted : params.value;
  // return true to tell the grid we refreshed successfully
  return true;
};

// gets called when the cell is removed from the grid
DateCellRenderer.prototype.destroy = function() {

};
