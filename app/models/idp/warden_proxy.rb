###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Warden-compatible proxy for JWT-based authentication.
#
# Provides a warden-like interface for code that expects warden.user to be available,
# so existing callers keep working without a real Warden session. Only the :user scope
# carries a user under JWT; :hmis_user ceases to exist at cutover seam 6.
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

  # All public methods mirror Warden::Proxy's positional scope / trailing-options-hash
  # convention rather than keyword args: Devise and Warden call these positionally (and via
  # splatted `[strategies..., opts]`), so a `*args` signature is what keeps them compatible.
  # A bare `*args` also absorbs the keyword `scope:` form Devise uses elsewhere.

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

  # No-op for JWT-based auth; authentication is handled via the token.
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

  def set_user(user, *args)
    @user = user if user_scope?(_scope(args))
  end

  # In JWT-based authentication, the session is managed by Rails, not Warden.
  def session(*_args)
    @session
  end

  # Devise's sign_out(scope) routes here as logout(scope); only clear when the :user scope
  # (or no scope) is targeted, so signing out a non-:user mapping leaves the real user intact.
  def logout(*scopes)
    @user = nil if scopes.empty? || scopes.map(&:to_sym).include?(:user)
  end

  # Strategy-related machinery has no meaning under JWT (there are no Warden strategies to run
  # or cache), but Devise's sign_in / sign_out / failure paths still call these on the proxy.
  # No-ops / nil keep those paths working.
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
