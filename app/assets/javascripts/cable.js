//= require actioncable
//= require_self
(function() {
  this.App || (this.App = {});
  App.cable = ActionCable.createConsumer();
  // ActionCable.logger.enabled = true;
  // ActionCable.ConnectionMonitor.staleThreshold = 10;
}).call(this);
