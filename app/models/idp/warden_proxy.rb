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

  def user(scope: :user)
    @user if user_scope?(scope)
  end

  def authenticated?(scope: :user)
    user_scope?(scope) && @user.present?
  end

  def authenticate?(scope: :user)
    authenticated?(scope: scope)
  end

  # No-op for JWT-based auth; authentication is handled via the token.
  def authenticate!(scope: :user, **)
    @user if user_scope?(scope)
  end

  def set_user(user, scope: :user, _store: false, _run_callbacks: false)
    @user = user if user_scope?(scope)
  end

  # In JWT-based authentication, the session is managed by Rails, not Warden.
  def session(*_args)
    @session
  end

  private def user_scope?(scope)
    scope&.to_sym == :user
  end
end
