//= require cable
//= require_self
(function() {
  this.App || (this.App = {});

  this.App.initTestChannel = function() {
    console.log('Subscribing to test channel');

    App.cable.subscriptions.create({ channel: "TestChannel" }, {
      received: function(data) {
        console.log('received');
        this.appendLine(data);
      },

      appendLine: function(data) {
        var html = this.createLine(data);
        var element = document.querySelector("[data-actioncable='here']");
        element.insertAdjacentHTML("beforeend", html);
      },

      createLine: function(data) {
        return '<article class="test-line"><span class="body">' + data["message"] + '</span></article>';
      }
    });
  };

}).call(this);
