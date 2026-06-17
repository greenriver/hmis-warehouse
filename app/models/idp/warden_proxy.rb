###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Warden-compatible proxy for JWT-based authentication.
#
# Provides a warden-like interface for code that expects warden.user to be available,
# so existing callers keep working without a real Warden session. Only the :user scope
# carries a user under JWT.
#
# Non-:user scopes answer falsey (matching real Warden) rather than raising: Devise's
# scope-iterating helpers (e.g. signed_in?) probe authenticate?(scope: :hmis_user) on
# every registered mapping, and :hmis_user remains a Devise mapping until seam 6. A raise
# here would turn a routine "is the hmis_user signed in? no" probe into a 500.
class Idp::WardenProxy
  def initialize(user, session: nil)
    @user = user
    @session = session
  end

  # The scope-accepting methods take `*args` rather than a keyword `scope:`, mirroring
  # Warden::Proxy: Devise and Warden call these positionally and via splatted
  # `[strategies..., opts]`, and `*args` (parsed by _scope) absorbs all those forms plus the
  # keyword `scope:` form Devise uses elsewhere.

  def user(*args)
    @user if user_scope?(_scope(args))
  end

  def authenticated?(*args)
    result = !!user(*args)
    yield if result && block_given?
    result
  end

  def authenticate?(*args)
    result = !!authenticate(*args)
    yield if result && block_given?
    result
  end

  # Real Warden runs strategies here; under JWT the token already authenticated us, so there's
  # nothing to run — just hand back the resolved user (identical to #user).
  def authenticate(*args)
    @user if user_scope?(_scope(args))
  end

  # Real Warden throws :warden on failure so its failure app can redirect to login. There is no
  # Warden failure app under JWT, and the cutover invariant is that an unauthenticated request
  # never reaches a proxy-backed gate (the :user gate is handled upstream in Idp::CurrentUser).
  # So reaching here without a resolved user means a scope is leaning on the proxy as its sole
  # gate: fail loudly rather than silently authorize. Dial back to returning nil if too aggressive.
  def authenticate!(*args)
    user = authenticate(*args)
    raise Warden::NotAuthenticated, "Idp::WardenProxy#authenticate! got no authenticated user for scope #{_scope(args).inspect}" unless user

    user
  end

  # Devise's sign_in routes here, so the method must exist. Like logout, it cannot actually
  # establish a session: the user is established by the JWT upstream (oauth2-proxy / okta), and
  # current_user is resolved from the token, not from @user. We still set the local copy so
  # warden.user is consistent within the request when the :user scope is targeted.
  def set_user(user, *args)
    @user = user if user_scope?(_scope(args))
  end

  # In JWT-based authentication, the session is managed by Rails, not Warden.
  def session(*_args)
    @session
  end

  # Devise's sign_out / sign_out_all_scopes route here, so the method must exist. But it cannot
  # actually log anyone out: the JWT lives in the X-Forwarded-Access-Token request header (the
  # source of truth), not in this proxy, and current_user is resolved from that token, not from
  # @user. Real sign-out is the redirect to oauth2-proxy's sign-out endpoint in
  # Users::SessionsController#respond_to_on_destroy. We still clear the local copy so warden.user
  # is consistent within the request when the :user scope (or no scope) is targeted.
  def logout(*scopes)
    @user = nil if scopes.empty? || scopes.map(&:to_sym).include?(:user)
  end

  # Warden strategy machinery — with no strategies under JWT there's nothing to cache or lock.
  # Devise's sign-out path still calls these (sign_out clears the cache, sign_out_all_scopes
  # locks), so keep them as no-ops.
  def clear_strategies_cache!(*_args)
  end

  def lock!
  end

  # Devise's bypass_sign_in writes the user straight to the session serializer (skipping
  # set_user). Under JWT there is no Warden session store to write to, so hand back a sink
  # that swallows store/delete and answers fetch with nil.
  def session_serializer
    @session_serializer ||= NullSessionSerializer.new
  end

  # Also strategy machinery: with no strategies there's no winning strategy and no auth-failure
  # message. Devise's CSRF-cleanup and failure-app paths read these; nil is the honest answer.
  def winning_strategy
    nil
  end

  def message
    nil
  end

  # Parse the scope from Warden's flexible call forms: a positional symbol (`user(:admin)`),
  # a trailing/only options hash (`user(scope: :admin)` or splatted `[:strategy, {scope:}]`),
  # or nothing (defaults to :user).
  private def _scope(args)
    opts = args.last.is_a?(Hash) ? args.last : {}
    scope = opts[:scope]
    scope ||= args.first unless args.first.is_a?(Hash)
    (scope || :user).to_sym
  end

  private def user_scope?(scope)
    scope == :user
  end

  # Stand-in for Warden::SessionSerializer; the session is Rails-managed under JWT.
  class NullSessionSerializer
    def store(*)
    end

    def delete(*)
    end

    def fetch(*)
      nil
    end
  end
end
