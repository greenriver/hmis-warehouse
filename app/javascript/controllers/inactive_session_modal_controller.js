import { Controller } from '@hotwired/stimulus';

const WARNING_WHEN_REMAINING_SECS = 5 * 60; // 5 minutes
const DEFAULT_POLL_SECS = 3;

const MAX_POLL_COUNT = (60 * 60 * 10) / DEFAULT_POLL_SECS; // about 10 hours
const TS_KEY = 'session_last_request_ts';
const UID_KEY = 'session_user_id';
// JWT arm: browser-clock seconds at which the token expires, shared so all tabs count down together.
// Stored with the start time of the request that reported it, and the newest request wins, not the
// max: every tab shares one oauth2-proxy cookie, so the newest request carries the current token,
// and a failed refresh must be able to pull the expiry earlier.
const EXPIRES_KEY = 'session_expires_at';
// Server-Timing entry name set by ApplicationController#set_app_user_header.
const SESSION_TIMING_NAME = 'app-session-remaining';

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

const readExpiry = () => {
  const stored = shared.getValue(EXPIRES_KEY);
  return stored ? JSON.parse(stored) : {};
};

// `requestedAt` is when the request started. The server reads the token's remaining seconds early in
// the request, so anchoring there errs early by network latency, not late by the action's run time.
// A write from an older request (a slow response, or a background tab's delayed observer) is dropped.
const saveExpiry = (remainingSecs, requestedAt) => {
  if (readExpiry().requestedAt > requestedAt) return;
  shared.saveValue(EXPIRES_KEY, JSON.stringify({ requestedAt, expiresAt: requestedAt + remainingSecs }));
};

// Wall-clock seconds `msAgo` milliseconds of monotonic time before now. Every `requestedAt` must be on
// the wall clock that getTimestamp and mainLoop use. performance.timeOrigin + a monotonic stamp isn't:
// the monotonic clock stops while the machine sleeps, so on a page loaded before a sleep that sum
// lags the wall clock by the sleep's length.
const wallClockSecsAgo = (msAgo) => getTimestamp() - msAgo / 1000;

export default class extends Controller {
  static get targets() {
    return ['timeRemaining', 'modal', 'alert', 'alertMessage', 'renewFailed', 'renewButton', 'dismissButton'];
  }

  connect() {
    this.initialUserIdValue = this.data.get('initial-user-id-value');
    this.sessionLifetimeSecsValue = parseInt(this.data.get('session-lifetime-secs-value'));
    // Anchor the forwarded token's remaining seconds to the browser clock, so the countdown never
    // subtracts browser time from a server-issued instant. Absent on the Devise arm, which seeds a lifetime.
    const remainingSecs = parseInt(this.data.get('session-remaining-secs-value'));
    this.tokenExpiryDriven = !Number.isNaN(remainingSecs);
    // Navigation start (performance.now() is measured from it), at or before the request that rendered the seed.
    if (this.tokenExpiryDriven) saveExpiry(remainingSecs, wallClockSecsAgo(performance.now()));
    shared.saveValue(UID_KEY, this.initialUserIdValue);
    if (!this.initialUserIdValue) {
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
      warningDismissed: false,
    };
    $(document).on('ajaxComplete', this.handleAjaxComplete.bind(this));
    if (this.tokenExpiryDriven) this.observeSessionTiming();
    this.mainLoop();
    document.addEventListener('shown.bs.modal', this.ensureOneBackdrop);
    window.onstorage = () => { };
  }

  disconnect() {
    this.state.xhr && this.state.xhr.abort();
    document.removeEventListener('shown.bs.modal', this.ensureOneBackdrop);
    $(document).off('ajaxComplete', this.handleAjaxComplete.bind(this));
    this.sessionTimingObserver && this.sessionTimingObserver.disconnect();
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
    const ts = parseInt(shared.getValue(TS_KEY));
    if (ts) {
      const expires = this.tokenExpiryDriven ? readExpiry().expiresAt : ts + this.sessionLifetimeSecsValue;
      // JWT arm with a current_user but no token expiry: no seed to count down, so hold at
      // not-expiring (a NaN countdown would otherwise render a false "session expired").
      const remaining = Number.isFinite(expires) ? Math.max(expires - getTimestamp(), 0) : Number.MAX_VALUE;
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
      if (!state.warningDismissed) this.renderWarning(state);
    } else {
      // Out of the warning window again (e.g. signed in again in another tab): next warning starts fresh.
      state.warningDismissed = false;
      this.toggleRenewFailed(false);
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
    if (xhr.status >= 500) return;
    // The JWT arm's expiry comes from observeSessionTiming, which sees these requests too. It has no
    // skips: any request carrying the oauth2-proxy cookie can refresh the token.
    if (!this.tokenExpiryDriven) {
      if (settings && settings.url == '/messages/poll') return;
      if (settings && settings.url.includes('skip_trackable=true')) return;
    }
    const userId = xhr.getResponseHeader('X-app-user-id');
    shared.saveValue(UID_KEY, userId);
    if (userId) {
      shared.saveValue(TS_KEY, getTimestamp());
    }
  }

  // Resource Timing exposes the Server-Timing entry for every same-origin request (fetch, XHR,
  // iframes). `buffered` replays requests that finished before this controller connected.
  observeSessionTiming() {
    this.sessionTimingObserver = new PerformanceObserver((list) => {
      // A batch isn't guaranteed to be in request order, and the newest request carries the current token.
      let latest;
      list.getEntries().forEach((entry) => {
        // serverTiming is missing in older browsers (e.g. Safari < 16.4): the countdown then moves
        // only on page load and keepalive.
        const timing = (entry.serverTiming || []).find((t) => t.name === SESSION_TIMING_NAME);
        if (timing && !Number.isNaN(parseInt(timing.description)) && (!latest || entry.requestStart > latest.entry.requestStart)) {
          latest = { entry, timing };
        }
      });
      if (!latest) return;
      // Anchor to the entry's own timing, not now: observer callbacks can be delayed, e.g. in background tabs.
      const requestedAt = wallClockSecsAgo(performance.now() - latest.entry.requestStart);
      saveExpiry(parseInt(latest.timing.description), requestedAt);
    });
    this.sessionTimingObserver.observe({ type: 'resource', buffered: true });
  }

  handleLogin(event) {
    event.preventDefault();
    window.location.reload();
  }

  handleRenewSession(event) {
    event.preventDefault();
    if (this.state.xhr) return;
    const requestedAt = getTimestamp();
    const success = (data) => {
      this.state.xhr = undefined;
      // The token didn't refresh (the IdP session is likely gone). A reload wouldn't help: oauth2-proxy
      // keeps the old token until it expires. Say so, and let the user close the modal to save their work.
      if (this.tokenExpiryDriven && data && data.remaining_seconds < WARNING_WHEN_REMAINING_SECS) {
        saveExpiry(data.remaining_seconds, requestedAt);
        this.toggleRenewFailed(true);
        return;
      }
      this.applyKeepaliveExpiry(data, requestedAt);
      this.hideWarning();
    };
    const error = () => {
      window.location.reload();
    };
    // No dataType: 'json' — the Devise keepalive returns head :ok with an empty body, which a forced
    // JSON parse would fail, routing this success through `error` (a page reload).
    this.state.xhr = $.ajax(event.currentTarget.href, {
      method: 'POST',
      success,
      error,
    });
  }

  toggleRenewFailed(failed) {
    this.renewFailedTarget.classList.toggle('d-none', !failed);
    this.renewButtonTarget.classList.toggle('d-none', failed);
    this.dismissButtonTarget.classList.toggle('d-none', !failed);
  }

  // Keeps the modal closed for the rest of the countdown; at 0 the page still clears as usual.
  dismissWarning(event) {
    event.preventDefault();
    this.state.warningDismissed = true;
    this.hideWarning();
  }

  applyKeepaliveExpiry(data, requestedAt) {
    if (!this.tokenExpiryDriven || !data || !Number.isFinite(data.remaining_seconds)) return;
    // Browser-clock basis, like connect(): the payload's absolute expiration_time would carry skew.
    saveExpiry(data.remaining_seconds, requestedAt);
    this.state.remaining = Number.MAX_VALUE;
  }
}
