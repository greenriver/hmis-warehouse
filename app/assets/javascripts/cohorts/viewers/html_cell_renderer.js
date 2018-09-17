function HtmlCellRenderer () {}

// gets called once before the renderer is used
HtmlCellRenderer.prototype.init = function(params) {
  this.params = params;
  this.row = params.data[params.colDef.field]
  this.refresh(params);
};

// gets called once when grid ready to insert the element
HtmlCellRenderer.prototype.getGui = function() {
  return this.eGui;
};

// gets called whenever the user gets the cell to refresh
HtmlCellRenderer.prototype.refresh = function(params) {
  var wrapper = document.createElement('div');
  wrapper.className = 'text-center'
  wrapper.innerHTML = this.params.value;
  if(this.row.comments) {
    wrapper.setAttribute('data-toggle', "tooltip");
    wrapper.setAttribute('data-title', this.row.comments);
    wrapper.setAttribute('data-placement', 'auto');
    wrapper.setAttribute('data-container', 'body');
    $(wrapper).tooltip();

  }
  this.eGui = wrapper;
  return true;
};

// gets called when the cell is removed from the grid
HtmlCellRenderer.prototype.destroy = function() {

};
