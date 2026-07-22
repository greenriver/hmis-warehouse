###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::Idp::UsersController < ApplicationController
  include ::Admin::Concerns::UserManagementBehavior
  include ::Admin::Idp::SoftFailure

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
  rescue ::Idp::ServiceError => e
    @user = User.new(new_user_params.except(:connector_id))
    flash.now[:error] = "Couldn't create the account in the identity provider: #{e.message}"
    render :new
  else
    emailed = with_idp_soft_failure("Account created, but the setup email couldn't be sent to #{@user.email}") do
      @user.idp_send_account_setup_email!
    end
    redirect_to edit_admin_user_path(@user), notice: creation_notice(@user, emailed: emailed)
  end

  def expire_password
    pushed = with_idp_soft_failure("Couldn't require a password change for #{@user.name} in the identity provider") do
      @user.idp_force_password_change!
    end
    # Unlike deactivate/reactivate there is no local change here
    return redirect_to(action: :index) unless pushed

    redirect_to({ action: :index }, notice: "#{@user.email} will be required to choose a new password on next login.")
  end

  # don't let users set these params from the form. expired_at has no IdP-side equivalent to
  # push, so it always stays local-only. Identity fields are stripped only when the profile is
  # locked (the IdP service can't accept writes); when it can, they flow through and get synced.
  private def externally_managed_param_keys
    keys = [:expired_at]
    keys += [:first_name, :last_name, :email] if @user&.profile_managed_by_idp?
    keys
  end

  # After the shared local `active: false` flip commits, disable the account in the IdP.
  private def after_deactivate
    with_idp_soft_failure("Local access revoked, but couldn't disable #{@user.name} in the identity provider") do
      @user.idp_deactivate!
    end
  end

  # After the shared local save commits, push any first_name/last_name/email change to the IdP.
  # No-ops when the user's IdP service doesn't accept profile writes (form disables those
  # inputs in that case, so user_params wouldn't carry a change anyway).
  private def after_profile_update
    changes = @user.saved_changes.slice('first_name', 'last_name', 'email')
    return if changes.empty?

    attributes = changes.transform_values(&:last).symbolize_keys
    with_idp_soft_failure("Local changes saved, but couldn't sync profile to #{@user.name}'s identity provider record") do
      @user.idp_update_profile!(attributes)
    end
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
