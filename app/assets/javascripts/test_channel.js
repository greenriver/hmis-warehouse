//= require cable
//= require_self
(function() {
  this.App || (this.App = {});

  this.App.initTestChannel = function() {
    console.log('Subscribing to test channel');

    App.cable.subscriptions.create({ channel: "TestChannel" }, {
      received(data) {
        console.log('received');
        this.appendLine(data);
      },

      appendLine(data) {
        const html = this.createLine(data);
        const element = document.querySelector("[data-actioncable='here']");
        element.insertAdjacentHTML("beforeend", html);
      },

      createLine(data) {
        return '<article class="test-line"><span class="body">' + data["message"] + '</span></article>';
      }
    })
  }

}).call(this);
