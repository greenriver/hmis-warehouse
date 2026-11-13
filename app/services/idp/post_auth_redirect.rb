###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Request-scoped helper for the post-auth redirect flow. Bound to the current `request` and
# `cookies` jar, it knows how to:
#   - `capture` the URL a signed-out user was trying to reach, and
#   - `resolve` where to send them once they're back from OAuth2-proxy.
#
# The original URL is stashed in an encrypted, single-use cookie so it survives the
# OAuth2-proxy round trip even if the `rd` parameter is dropped. Because OAuth2-proxy is a
# same-origin sidecar, the browser replays the cookie on the post-auth request regardless of
# how many redirect hops happen — and because it lives client-side, an unauthenticated request
# can't use it to grow shared server state.
module Idp
  class PostAuthRedirect
    # Cap on the redirect value we'll persist. A real in-app path — even a filter-heavy report
    # URL — is well under this; anything longer is junk or a deliberately oversized value, so we
    # refuse to store it. Kept tight on purpose: the encrypted cookie stores ciphertext + IV +
    # tag + envelope (~1.35x + overhead), so 1KB of plaintext stays comfortably under the ~4KB
    # browser cookie limit, past which the browser silently drops the cookie.
    MAX_REDIRECT_URL_LENGTH = 1_024

    # Name of the encrypted cookie holding the post-auth redirect backup.
    REDIRECT_COOKIE = :idp_post_auth_redirect

    def initialize(request:, cookies:)
      @request = request
      @cookies = cookies
    end

    # Resolve the post-auth redirect URL, checking sources in priority order:
    # 1. `rd` query parameter (from OAuth2-proxy), 2. the encrypted backup cookie,
    # 3. X-Auth-Request-Redirect header, 4. user.my_root_path. Only returns safe URLs.
    def resolve(params:, user: nil)
      redirect_url = params[:rd].presence || read.presence || @request.headers['X-Auth-Request-Redirect'].presence || user&.my_root_path

      # The backup cookie is single-use: once we've resolved a post-auth redirect it's spent,
      # so clear it regardless of which source won (the `rd` param short-circuits the cookie
      # read above, so this also drops a stale backup in that case).
      clear

      redirect_url if redirect_url.present? && self.class.safe?(redirect_url, @request)
    end

    # Capture the full request path for post-auth redirect, excluding OAuth2-proxy /
    # sign-in/sign-out endpoints and AJAX requests. Stores a cookie backup.
    def capture
      # Only capture a normal page navigation we can send the user back to after sign-in:
      # a GET (you can't redirect someone back to a POST — that also covers GraphQL), not a
      # background/AJAX request, and an HTML page (don't bounce a browser to a JSON/API URL).
      return nil unless @request.get?
      return nil if @request.xhr?
      return nil unless @request.format.html?
      return nil if @request.path.start_with?('/oauth2/')
      return nil if @request.path.in?(['/users/sign_in', '/users/sign_out', '/hmis/login', '/hmis/logout'])

      url = @request.fullpath
      return nil if url.blank?

      # Store a cookie backup (in case OAuth2-proxy doesn't preserve the rd parameter)
      store(url)

      url
    end

    # Open-redirect guard: allow relative paths and same-origin URLs only; reject external
    # hosts and dangerous protocols (javascript:, data:, vbscript:). Pure predicate — no
    # instance state — so it's exposed at the class level.
    def self.safe?(url, request)
      return false if url.blank?

      # Reject protocol-relative ("//host") and backslash-obfuscated ("/\host", "\host")
      # URLs first — they start with a slash but browsers treat them as absolute
      # navigations to an external host, slipping past the relative-path allow below.
      return false if url.start_with?('//', '/\\', '\\')

      # Allow relative paths (starting with /)
      return true if url.start_with?('/')

      begin
        uri = URI.parse(url)
      rescue URI::InvalidURIError
        return false
      end

      return false if ['javascript', 'data', 'vbscript'].include?(uri.scheme&.downcase)

      # Allow same-origin URLs (or URLs without a host)
      return true if uri.host == request.host || uri.host.blank?

      false
    end

    private

    def store(url)
      return unless url.present?
      return if url.length > MAX_REDIRECT_URL_LENGTH

      @cookies.encrypted[REDIRECT_COOKIE] = cookie_options.merge(value: url)
    end

    def read
      @cookies.encrypted[REDIRECT_COOKIE]
    end

    def clear
      @cookies.delete(REDIRECT_COOKIE)
    end

    # Mirror the session cookie's hardening (see config/initializers/session_store.rb).
    # Short expiry as a safety net; the redirect is consumed right after sign-in.
    def cookie_options
      {
        expires: 10.minutes,
        httponly: true,
        same_site: :lax,
        secure: !Rails.env.test?,
      }
    end
  end
end
