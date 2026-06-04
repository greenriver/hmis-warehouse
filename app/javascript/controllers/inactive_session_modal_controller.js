import { Controller } from "@hotwired/stimulus"

// If we only have 5 minutes left, show the modal warning
const WARNING_WHEN_REMAINING_SECS = 5 * 60; // 5 minutes
// oauth2-proxy refreshes tokens when within 10 minutes of expiration (cookie_refresh="10m")
// So we should trigger refresh when within this window
const REFRESH_WHEN_REMAINING_SECS = 10 * 60; // 10 minutes (matches oauth2-proxy cookie_refresh window)
const POLL_INTERVAL_SECS = 30; // Check every 30 seconds

export default class extends Controller {
  static get targets() {
    return ['timeRemaining', 'modal', 'alert', 'alertMessage'];
  }

  static values = { expiresAt: Number }

  connect() {
    if (!this.expiresAtValue) {
      // No expiration time available, don't monitor
      return;
    }

    // Stop any existing polling from previous connections
    this.stopPolling();

    this.state = {
      expired: false,
      checking: false,
      refreshRequested: false,
      lastRefreshAttempt: null,
    };

    // Check if we should refresh the session on page load
    // Only refresh if token is within refresh window - this ensures activity-based refresh
    const now = Math.floor(Date.now() / 1000);
    const remaining = this.expiresAtValue - now;
    if (remaining > 0 && remaining <= REFRESH_WHEN_REMAINING_SECS && !this.state.refreshRequested) {
      console.log('Session within refresh window, requesting refresh');
      this.refreshSession();
    }

    // Start polling for expiration
    this.startPolling();

    // Handle modal backdrop cleanup
    document.addEventListener('shown.bs.modal', this.ensureOneBackdrop.bind(this));

    // Handle modal dismissal to properly reset state
    $(this.modalTarget).on('hidden.bs.modal', () => {
      if (this.modalShown) {
        this.modalShown = false;
        if (this.updateInterval) {
          clearInterval(this.updateInterval);
          this.updateInterval = null;
        }
        // Restart regular polling
        this.startPolling();
      }
    });
  }

  disconnect() {
    this.stopPolling();
    document.removeEventListener('shown.bs.modal', this.ensureOneBackdrop.bind(this));
    // Remove modal event handler
    $(this.modalTarget).off('hidden.bs.modal');
    // Hide modal if shown
    if (this.modalShown) {
      $(this.modalTarget).modal('hide');
    }
    // Stop update interval if running
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }

  startPolling() {
    // Stop any existing polling first to prevent multiple intervals
    this.stopPolling();
    this.checkExpiration();
    this.pollInterval = setInterval(() => {
      this.checkExpiration();
    }, POLL_INTERVAL_SECS * 1000);
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  }

  checkExpiration() {
    if (this.state.expired || this.state.checking) {
      return;
    }

    this.state.checking = true;

    const now = Math.floor(Date.now() / 1000);
    const remaining = this.expiresAtValue - now;

    console.debug('remaining', remaining);
    console.debug('REFRESH_WHEN_REMAINING_SECS', REFRESH_WHEN_REMAINING_SECS);
    console.debug('WARNING_WHEN_REMAINING_SECS', WARNING_WHEN_REMAINING_SECS);

    if (remaining <= 0) {
      // Session expired - show error and reload
      this.state.expired = true;
      this.stopPolling();
      this.renderAlert('Your session has expired.');
      setTimeout(() => {
        window.location.href = '/';
      }, 2000);
    } else if (remaining <= WARNING_WHEN_REMAINING_SECS) {
      // Show warning modal when within warning window
      this.renderWarning(remaining);
    } else {
      // Hide modal if shown
      this.hideWarning();
    }

    this.state.checking = false;
  }

  refreshSession() {
    // Prevent multiple refresh requests without a page load
    if (this.state.refreshRequested) {
      return;
    }

    // Prevent refreshing too frequently (at most once per minute)
    const now = Date.now();
    if (this.state.lastRefreshAttempt && (now - this.state.lastRefreshAttempt) < 60000) {
      return;
    }

    this.state.refreshRequested = true;
    this.state.lastRefreshAttempt = now;

    // Call the refresh endpoint to trigger oauth2-proxy token refresh
    // This is only called from connect() on page load, ensuring activity-based refresh
    // oauth2-proxy will automatically refresh the token if it's within the cookie_refresh window (2m)
    fetch('/session_keepalive', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      credentials: 'same-origin',
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        } else {
          throw new Error(`Session refresh failed: ${response.status}`);
        }
      })
      .then(data => {
        // Update the expiration time with the new value from the server
        // If oauth2-proxy refreshed the token, this will be the new expiration time
        // If it didn't refresh (token not within 2-minute window), this will be the same
        if (data.expiration_time) {
          const oldExpiresAt = this.expiresAtValue;
          this.expiresAtValue = data.expiration_time;

          // If the expiration time increased, the refresh was successful
          if (this.expiresAtValue > oldExpiresAt) {
            console.debug('Session refreshed successfully, new expiration:', new Date(this.expiresAtValue * 1000));
            // Hide warning modal since session was extended
            this.hideWarning();
            // Keep refresh flag set longer since refresh was successful
            setTimeout(() => {
              this.state.refreshRequested = false;
            }, 300000); // Reset after 5 minutes
          } else {
            // Token wasn't refreshed (not within oauth2-proxy's 2-minute window)
            // Reset flag sooner to allow retry when we get closer to expiration
            setTimeout(() => {
              this.state.refreshRequested = false;
            }, 120000); // Reset after 2 minutes
          }
        } else {
          // No expiration time returned, reset flag immediately
          this.state.refreshRequested = false;
        }
      })
      .catch(error => {
        console.error('Session refresh error:', error);
        // Reset flag on error so we can retry, but wait a bit
        setTimeout(() => {
          this.state.refreshRequested = false;
        }, 60000); // Wait 1 minute before allowing retry
      });
  }

  renderWarning(remainingSeconds) {
    const minRemaining = Math.floor(remainingSeconds / 60);
    const secRemaining = Math.floor(remainingSeconds % 60);
    const formattedMin = minRemaining.toString().padStart(2, '0');
    const formattedSec = secRemaining.toString().padStart(2, '0');
    this.timeRemainingTarget.innerHTML = `${formattedMin}:${formattedSec}`;

    // Show modal if not already shown
    if (!this.modalShown) {
      $(this.modalTarget).modal('show');
      this.modalShown = true;

      // Stop regular polling and update timer every second instead
      this.stopPolling();
      this.updateInterval = setInterval(() => {
        const now = Math.floor(Date.now() / 1000);
        const remaining = this.expiresAtValue - now;

        if (remaining <= 0) {
          clearInterval(this.updateInterval);
          this.hideWarning();
          return;
        }

        const minRemaining = Math.floor(remaining / 60);
        const secRemaining = Math.floor(remaining % 60);
        const formattedMin = minRemaining.toString().padStart(2, '0');
        const formattedSec = secRemaining.toString().padStart(2, '0');
        this.timeRemainingTarget.innerHTML = `${formattedMin}:${formattedSec}`;
      }, 1000);
    }
  }

  hideWarning() {
    if (this.modalShown) {
      $(this.modalTarget).modal('hide');
      this.modalShown = false;
    }
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
    // Restart normal polling
    this.startPolling();
  }

  renderAlert(message) {
    this.hideWarning();
    const $e = $(this.alertMessageTarget);
    if ($e.text() !== message) $e.text(message);
    $(this.alertTarget).removeClass('d-none');
  }

  handleRenewSession(event) {
    event.preventDefault();
    this.refreshSession();
  }

  ensureOneBackdrop() {
    document.querySelectorAll('.modal-backdrop').forEach((node, i) => {
      if (i > 0) node.remove();
    });
  }
}
