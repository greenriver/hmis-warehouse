//= require action_cable
//= require_self
(function() {
  this.App || (this.App = {});
  App.cable = ActionCable.createConsumer("/cable");
}).call(this);
