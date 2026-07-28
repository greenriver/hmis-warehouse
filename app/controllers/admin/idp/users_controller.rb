###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::Idp::UsersController < ApplicationController
  include ::Admin::Concerns::UserManagementBehavior

  before_action :require_user_creation_available!, only: [:new, :create]
  before_action :set_connectors, only: [:new, :create]
  helper_method :idp_user_creation_available?

  # Fall back to the shared admin/users templates for any views this arm doesn't override:
  def _prefixes
    @_prefixes ||= [self.class.controller_path, 'admin/users'] + ApplicationController._prefixes
  end

  def new
    @user = User.new
  end

  # The shared save and the IdP push share a transaction, so both of these arrive with the local
  # write already unwound — there is nothing saved to announce, only a refusal to explain.
  def update
    super
  rescue ::Idp::ConflictError => e
    # The IdP holds this address on another account: a form problem, so name the field the way a
    # local uniqueness failure would.
    @user.errors.add(:email, "is already registered with #{e.idp_name}")
    flash.now[:error] = 'Please review the form problems below'
    render :edit
  rescue ::Idp::ServiceError => e
    # Misconfigured or unreachable IdP. The form has no problem to point at, so say what actually
    # happened and page — this needs someone to look at the connector.
    Sentry.capture_exception_with_info(e, "Couldn't sync #{@user.name}'s profile to the identity provider")
    flash.now[:error] = "Couldn't reach the identity provider to save these changes (#{e.message}). Nothing was saved."
    render :edit
  end

  def destroy
    super
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't disable #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't deactivate #{@user.name}: #{e.message}. #{@user.name} still has access.")
  end

  def create
    @user = ::Idp::AdminUserCreator.call(
      connector_id: create_connector_id,
      email: new_user_params[:email],
      first_name: new_user_params[:first_name],
      last_name: new_user_params[:last_name],
    )
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    flash.now[:error] = 'Please review the form problems below'
    render :new
  rescue ::Idp::ConflictError => e
    # The address is registered to a different account in the IdP. AdminUserCreator links to an
    # existing account by email rather than colliding with it, so this is the narrower case of a
    # username/email clash inside the realm — a form problem, not a broken connector.
    @user = User.new(new_user_params.except(:connector_id))
    @user.errors.add(:email, "is already registered with #{e.idp_name}")
    flash.now[:error] = 'Please review the form problems below'
    render :new
  rescue ::Idp::ServiceError => e
    @user = User.new(new_user_params.except(:connector_id))
    flash.now[:error] = "Couldn't create the account in the identity provider: #{e.message}"
    render :new
  else
    # The account exists in both places by now, so a mail failure is not a sync problem — swallowing
    # it keeps the admin on the edit form with the account they just made, and the setup email can be
    # re-sent from there.
    emailed = begin
      @user.idp_send_account_setup_email!
    rescue ::Idp::ServiceError => e
      Sentry.capture_exception_with_info(e, "Account created, but the setup email couldn't be sent to #{@user.email}")
      flash[:alert] = "The setup email couldn't be sent to #{@user.email}: #{e.message}"
      false
    end
    redirect_to edit_admin_user_path(@user), notice: creation_notice(@user, emailed: emailed)
  end

  # Unlike deactivate/reactivate there is no local change here, so there is no transaction to abort
  # and nothing to keep in sync — a failure is reported and that's the end of it.
  def expire_password
    pushed = @user.idp_force_password_change!
    # An account that was never IdP-managed has nothing to push; say nothing rather than claim a
    # password reset was scheduled.
    return redirect_to(action: :index) unless pushed

    redirect_to({ action: :index }, notice: "#{@user.email} will be required to choose a new password on next login.")
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't require a password change for #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't require a password change for #{@user.name}: #{e.message}")
  end

  # don't let users set these params from the form. expired_at has no IdP-side equivalent to
  # push, so it always stays local-only. Identity fields are stripped only when the profile is
  # locked (the IdP service can't accept writes); when it can, they flow through and get synced.
  private def externally_managed_param_keys
    keys = [:expired_at]
    keys += [:first_name, :last_name, :email] if @user&.profile_managed_by_idp?
    keys
  end

  # Disable the account in the IdP from inside the transaction holding the local `active: false`
  # flip, so a refused write takes the local flip with it. No-ops for a connector with no management
  # API, which keeps local deactivation available when the IdP link is gone.
  private def after_deactivate
    @user.idp_deactivate!
  end

  # Push any first_name/last_name/email change to the IdP from inside the transaction holding the
  # local save, so a refused write takes the local edit with it. No-ops when the user's IdP service
  # doesn't accept profile writes (form disables those inputs in that case, so user_params wouldn't
  # carry a change anyway).
  private def after_profile_update
    changes = @user.saved_changes.slice('first_name', 'last_name', 'email')
    return if changes.empty?

    attributes = changes.transform_values(&:last).symbolize_keys
    @user.idp_update_profile!(attributes)
  end

  # IdP arm: 2FA is handled by the identity provider, not seeded locally.
  private def initialize_two_factor_secret_for_edit
  end

  # IdP arm: the otp_required_for_login select self-gates; no local 2FA to disable.
  private def disable_two_factor_if_requested
  end

  # IdP arm: no local email lifecycle (and no Devise :confirmable) to suppress.
  private def skip_email_reconfirmation
  end

  private def creation_notice(user, emailed:)
    parts = ["Account created for #{user.email}."]
    parts << 'A setup email has been sent.' if emailed
    parts << 'Assign roles and access below.'
    parts.join(' ')
  end

  # Active configs whose IdP can provision new accounts. A deployment may have several
  # (one per realm), so the create form lets the admin choose when there is more than one.
  # Empty under Devise: provisioning routes through the IdP and relies on Idp::Support, which
  # is only mixed into the user models under AuthMethod.jwt?.
  private def available_connectors
    return [] unless AuthMethod.jwt?

    @available_connectors ||= ::Idp::ServiceConfig.active.order(:name, :id).select do |config|
      config.to_service.supports_user_creation?
    rescue ::Idp::ServiceError
      false
    end
  end

  private def idp_user_creation_available?
    available_connectors.any?
  end

  private def require_user_creation_available!
    return if idp_user_creation_available?

    redirect_to admin_users_path, alert: 'Creating user accounts is not available for this identity provider.'
  end

  private def set_connectors
    @connectors = available_connectors
  end

  # The connector to provision into: the admin's choice when offered, otherwise the sole
  # available connector. Constrained to available connectors so the param can't target an
  # arbitrary or creation-incapable config.
  private def create_connector_id
    chosen = new_user_params[:connector_id]
    ids = available_connectors.map(&:connector_id)
    return chosen if chosen.present? && ids.include?(chosen)

    ids.first
  end

  private def new_user_params
    params.require(:user).permit(:first_name, :last_name, :email, :connector_id)
  end
end
