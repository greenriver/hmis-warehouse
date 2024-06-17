const WARNING_WHEN_REMAINING_SECS = 5 * 60; // 5 minutes
const DEFAULT_POLL_SECS = 3;

const MAX_POLL_COUNT = (60 * 60 * 10) / DEFAULT_POLL_SECS; // about 10 hours
const TS_KEY = 'session_last_request_ts';
const UID_KEY = 'session_user_id';

const getTimestamp = () => {
  const now = new Date();
  return now.getTime() / 1000;
};

/*
 * local storage for cross-tab communication
 */
const shared = {
  saveValue: (key, value) => {
    window.localStorage.setItem(key, String(value));
  },
  getValue: (key) => {
    return window.localStorage.getItem(key) || undefined;
  },
};

/*
 * Handle session expiration
 *
 * - tracks the current user id and last authenticated request timestamp in local storage. Tracking occurs on page load and ajax requests
 * - poll local storage and adjust display to:
 *   A. Warn the user if the current session is about to expire
 *   B. Show an alert if the session expires
 *   C. Show an alert if the current user changes
 *   D. Refresh the page is the user logs in again in another tab after the page has expired
 *
 * - for debugging, see window.stimulusApp.controllers
 */

window.App.StimulusApp = window.App.StimulusApp || {};

App.StimulusApp.register(
  'inactive-session-modal',
  class extends Stimulus.Controller {
    static get targets() {
      return ['timeRemaining', 'modal', 'alert', 'alertMessage'];
    }

    connect() {
      this.initialUserIdValue = this.data.get('initial-user-id-value');
      this.sessionLifetimeSecsValue = parseInt(this.data.get('session-lifetime-secs-value'));

      // persist user id, saves as empty if the user has signed out
      shared.saveValue(UID_KEY, this.initialUserIdValue);
      if (!this.initialUserIdValue) {
        // no user id, so exit after updating the timestamp
        return;
      }
      shared.saveValue(TS_KEY, getTimestamp());

      this.state = {
        userId: this.initialUserIdValue,
        remaining: Number.MAX_VALUE,
        expired: false,
        invalid: false,
        xhr: undefined,
        pollCount: 0,
      };

      // when xhr requests are seen, update the shared store
      $(document).on('ajaxComplete', this.handleAjaxComplete);

      // start polling
      this.mainLoop();

      document.addEventListener('shown.bs.modal', this.ensureOneBackdrop);
      // IE / Edge Hack - add noop storage listener so cross-tab values are visible
      window.onstorage = function () {};
    }

    disconnect() {
      this.state.xhr && this.state.xhr.abort();
      document.removeEventListener('shown.bs.modal', this.ensureOneBackdrop);
      $(document).off('ajaxComplete', this.handleAjaxComplete);
      window.onstorage = null;
      if (this.mainLoopInterval) {
        clearTimeout(this.mainLoopInterval);
      }
    }

    mainLoop() {
      const { state } = this;
      state.pollCount += 1;

      // stop polling if we exceed the safety count
      if (state.pollCount > MAX_POLL_COUNT) {
        this.renderAlert('There was an error in your session');
        return;
      }
      if (state.invalid || state.expired) {
        // stop polling if session has expired
        return;
      }

      // check local storage for a new user id and session timeout
      state.userId = shared.getValue(UID_KEY);
      const ts = parseInt(shared.getValue(TS_KEY));
      if (ts) {
        const expires = ts + this.sessionLifetimeSecsValue;
        const delta = expires - getTimestamp();
        const remaining = delta > 0 ? delta : 0;
        state.remaining = remaining;
        // poll every second when showing a warning to update timer
        const timeout =
          remaining > 0 && remaining <= WARNING_WHEN_REMAINING_SECS
            ? 1000
            : DEFAULT_POLL_SECS * 1000;
        this.mainLoopInterval = setTimeout(() => this.mainLoop(), timeout);
      }

      // Note, when you logout state.userId is set to undefined, there seems to be
      // some situations where it is returned as the string "null", maybe a race condition?
      // For now, don't mark those as invalid
      console.log(state)
      if (state.userId !== this.initialUserIdValue && state.userId !== 'null') {
        // another tab has logged out or changed user
        state.invalid = true;
      } else if (state.remaining === 0) {
        state.expired = true;
      }

      if (state.expired) {
        this.renderAlert('Your session has expired.');
      } else if (state.invalid) {
        this.renderAlert('Your session is invalid. You may have signed out in another window.');
      } else if (state.remaining < WARNING_WHEN_REMAINING_SECS) {
        this.renderWarning(state);
      } else {
        this.hideWarning();
      }
    }

    renderWarning({ remaining }) {
      const minRemaining = Math.floor(remaining / 60);
      const secRemaining = Math.floor(remaining % 60);

      const formattedMin = minRemaining.toString().padStart(2, '0');
      const formattedSec = secRemaining.toString().padStart(2, '0');

      this.timeRemainingTarget.innerHTML = `${formattedMin}:${formattedSec}`;
      $(this.modalTarget).modal('show');
    }

    hideWarning() {
      $(this.modalTarget).modal('hide');
    }

    renderAlert(message) {
      this.clearBody();
      this.hideWarning();
      const $e = $(this.alertMessageTarget);
      if ($e.text() !== message) $e.text(message);
      $(this.alertTarget).removeClass('d-none');
    }

    /*
     * remove extra backdrops if warning modal is shown over another modal
     */
    ensureOneBackdrop() {
      document.querySelectorAll('.modal-backdrop').forEach((node, i) => {
        if (i > 0) node.remove();
      });
    }

    /*
     * remove all elements from the body and header except this controller's element
     */
    clearBody() {
      let node;
      if (!document.body) return;
      for (let i = 0; i < document.body.childNodes.length; i++) {
        node = document.body.childNodes[i];
        if (node.nodeType == 1 && !node.isEqualNode(this.element) && !node.classList.contains('o-header--page')) {
          document.body.removeChild(node);
        }
      }
    }

    /*
     * when an XHR request is received, update the shared store
     */
    handleAjaxComplete(_evt, xhr, settings) {
      // ignore responses related to message polling. Settings.url is the requested URL for this response
      if (settings && settings.url == '/messages/poll') return;
      if (settings && settings.url.includes('skip_trackable=true')) return;
      // ignore system errors
      if (xhr.status >= 500) return;

      const userId = xhr.getResponseHeader('X-app-user-id');
      shared.saveValue(UID_KEY, userId);
      if (userId) {
        // user id in header means we have a valid session
        shared.saveValue(TS_KEY, getTimestamp());
      }
    }

    /*
     * user clicks "log in" on the alert page
     */
    handleLogin(event) {
      event.preventDefault();
      window.location.reload();
    }

    /*
     * user clicks "continue using" on warning screen, refresh the session without a page load
     */
    handleRenewSession(event) {
      event.preventDefault();
      // already in flight
      if (this.state.xhr) return;

      const success = () => {
        this.state.xhr = undefined;
        this.hideWarning();
      };
      const error = () => {
        // network error occurred, do a full page reload
        window.location.reload();
      };
      this.state.xhr = $.ajax(event.currentTarget.href, {
        method: 'POST',
        success,
        error,
      });
    }
  },
);
