import { Controller } from "@hotwired/stimulus"

const WARNING_WHEN_REMAINING_SECS = 5 * 60; // 5 minutes
const DEFAULT_POLL_SECS = 3;

const MAX_POLL_COUNT = (60 * 60 * 10) / DEFAULT_POLL_SECS; // about 10 hours
const TS_KEY = 'session_last_request_ts';
const EXPIRES_KEY = 'session_expires_at';
const UID_KEY = 'session_user_id';

const getTimestamp = () => {
  const now = new Date();
  return now.getTime() / 1000;
};

const shared = {
  saveValue: (key, value) => {
    window.localStorage.setItem(key, String(value));
  },
  getValue: (key) => {
    return window.localStorage.getItem(key) || undefined;
  },
};

export default class extends Controller {
  static get targets() {
    return ['timeRemaining', 'modal', 'alert', 'alertMessage'];
  }

  connect() {
    this.initialUserIdValue = this.data.get('initial-user-id-value');
    this.sessionLifetimeSecsValue = parseInt(this.data.get('session-lifetime-secs-value'));
    shared.saveValue(UID_KEY, this.initialUserIdValue);
    if (!this.initialUserIdValue || !this.sessionLifetimeSecsValue || isNaN(this.sessionLifetimeSecsValue)) {
      return;
    }
    const now = getTimestamp();
    shared.saveValue(TS_KEY, now);
    // Store absolute expiration time (current time + session lifetime)
    const expiresAt = now + this.sessionLifetimeSecsValue;
    shared.saveValue(EXPIRES_KEY, expiresAt);
    this.state = {
      userId: this.initialUserIdValue,
      remaining: Number.MAX_VALUE,
      expired: false,
      invalid: false,
      xhr: undefined,
      pollCount: 0,
    };
    $(document).on('ajaxComplete', this.handleAjaxComplete.bind(this));
    this.mainLoop();
    document.addEventListener('shown.bs.modal', this.ensureOneBackdrop);
    window.onstorage = () => { };
  }

  disconnect() {
    this.state.xhr && this.state.xhr.abort();
    document.removeEventListener('shown.bs.modal', this.ensureOneBackdrop);
    $(document).off('ajaxComplete', this.handleAjaxComplete.bind(this));
    window.onstorage = null;
    if (this.mainLoopInterval) {
      clearTimeout(this.mainLoopInterval);
    }
  }

  mainLoop() {
    const { state } = this;
    state.pollCount += 1;
    if (state.pollCount > MAX_POLL_COUNT) {
      this.renderAlert('There was an error in your session');
      return;
    }
    if (state.invalid || state.expired) {
      return;
    }
    state.userId = shared.getValue(UID_KEY);
    const expiresAt = parseFloat(shared.getValue(EXPIRES_KEY));
    if (expiresAt) {
      const now = getTimestamp();
      const delta = expiresAt - now;
      const remaining = delta > 0 ? delta : 0;
      state.remaining = remaining;
      const timeout = remaining > 0 && remaining <= WARNING_WHEN_REMAINING_SECS ? 1000 : DEFAULT_POLL_SECS * 1000;
      this.mainLoopInterval = setTimeout(() => this.mainLoop(), timeout);
    }
    if (state.userId !== this.initialUserIdValue && state.userId !== 'null') {
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

  ensureOneBackdrop() {
    document.querySelectorAll('.modal-backdrop').forEach((node, i) => {
      if (i > 0) node.remove();
    });
  }

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

  handleAjaxComplete(_evt, xhr, settings) {
    if (settings && settings.url == '/messages/poll') return;
    if (settings && settings.url.includes('skip_trackable=true')) return;
    if (xhr.status >= 500) return;
    const userId = xhr.getResponseHeader('X-app-user-id');
    shared.saveValue(UID_KEY, userId);
    if (userId) {
      shared.saveValue(TS_KEY, getTimestamp());
      // Don't update expiration time - it's fixed from JWT
    }
  }

  handleLogin(event) {
    event.preventDefault();
    window.location.reload();
  }

  handleRenewSession(event) {
    event.preventDefault();
    if (this.state.xhr) return;
    const success = (data) => {
      this.state.xhr = undefined;
      // Update expiration time if server returned new expiration
      if (data && data.expiration_time) {
        const now = getTimestamp();
        const remainingSeconds = data.remaining_seconds || 0;
        const expiresAt = now + remainingSeconds;
        shared.saveValue(EXPIRES_KEY, expiresAt);
        // Update state to reflect new expiration
        this.state.remaining = remainingSeconds;
      }
      this.hideWarning();
    };
    const error = () => {
      // If refresh failed, reload the page to trigger re-authentication
      window.location.reload();
    };
    this.state.xhr = $.ajax(event.currentTarget.href, {
      method: 'POST',
      dataType: 'json',
      headers: {
        'Accept': 'application/json',
      },
      success,
      error,
    });
  }
}
