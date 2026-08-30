###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::Idp::UsersController < ApplicationController
  include ::Admin::Concerns::UserManagementBehavior

  # The create form's "Local account only" choice. Not blank: a blank value matches the record's nil
  # connector_id and would come back pre-selected on the radios, which must have no default.
  LOCAL_ONLY_CONNECTOR = 'local-only'

  before_action :set_connectors, only: [:new, :create]
  before_action :set_agencies, only: [:new, :create]
  helper_method :local_only_connector

  # Fall back to the shared admin/users templates for any views this arm doesn't override:
  def _prefixes
    @_prefixes ||= [self.class.controller_path, 'admin/users'] + ApplicationController._prefixes
  end

  def new
    @user = User.new
  end

  # super saves the record and pushes to the IdP in one transaction, so in these rescues the local
  # write is already rolled back — nothing to clean up, only a failure to report.
  def update
    super
  rescue ::Idp::ConflictError => e
    # The IdP holds this address on another account: a form problem, so name the field the way a
    # local uniqueness failure would.
    @user.errors.add(:email, "is already registered with #{e.idp_name}")
    flash.now[:error] = 'Please review the form problems below'
    render :edit
  rescue ::Idp::ServiceError => e
    # A misconfigured or unreachable IdP, not a form problem — capture to Sentry so someone
    # checks the connector.
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
    # Only the radios (several connectors, no default) can come back unanswered; the checkbox and
    # hidden-field forms always submit a value. Local-only submits LOCAL_ONLY_CONNECTOR, not blank.
    return render_missing_connector if @connectors.many? && new_user_params[:connector_id].blank?

    @user = ::Idp::AdminUserCreator.call(
      connector_id: create_connector_id,
      email: new_user_params[:email],
      first_name: new_user_params[:first_name],
      last_name: new_user_params[:last_name],
      agency_id: agency_scope.where(id: new_user_params[:agency_id]).pick(:id),
    )
  rescue ActiveRecord::RecordInvalid => e
    @user = e.record
    # AdminUserCreator doesn't set the virtual attribute, so put the admin's pick back on the record
    # for the re-rendered radios.
    @user.connector_id = new_user_params[:connector_id]
    flash.now[:error] = 'Please review the form problems below'
    render :new
  rescue ::Idp::ConflictError => e
    # The address is registered to a different account in the IdP. AdminUserCreator links to an
    # existing account by email rather than colliding with it, so this is the narrower case of a
    # username/email clash inside the realm — a form problem, not a broken connector.
    @user = User.new(new_user_params)
    @user.errors.add(:email, "is already registered with #{e.idp_name}")
    flash.now[:error] = 'Please review the form problems below'
    render :new
  rescue ::Idp::ServiceError => e
    @user = User.new(new_user_params)
    flash.now[:error] = "Couldn't create the account in the identity provider: #{e.message}"
    render :new
  else
    # The account exists both locally and in the IdP by now, so a mail failure is not a sync
    # problem — swallowing it keeps the admin on the edit form with the account they just made,
    # from which the setup email can be re-sent.
    emailed = begin
      @user.idp_send_account_setup_email!
    rescue ::Idp::ServiceError => e
      Sentry.capture_exception_with_info(e, "Account created, but the setup email couldn't be sent to #{@user.email}")
      flash[:alert] = "The setup email couldn't be sent to #{@user.email}: #{e.message}"
      false
    end
    redirect_to edit_admin_user_path(@user), notice: creation_notice(@user, emailed: emailed)
  end

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

  # expired_at has no IdP-side equivalent to push, so it always stays local-only. Identity fields
  # are stripped only when the profile is locked (the IdP service can't accept writes); when it
  # can, they flow through and get synced.
  private def externally_managed_param_keys
    keys = [:expired_at]
    keys += [:first_name, :last_name, :email] if @user&.profile_managed_by_idp?
    keys
  end

  # Disable the account in the IdP from inside the transaction holding the local deactivation, so a
  # refused write rolls that back too. No-ops for a connector with no management API, so local
  # deactivation still works when the IdP link is gone.
  #
  # idp_deactivate! returns :identity_missing when there's no identity row to push to; the local
  # revocation stands (the local flag is what closes Warehouse access), and we flash a warning because
  # the row still needs repair and whatever it pointed at may still be enabled in the IdP. Placed
  # before `super` for the reason at Admin::Idp::InactiveUsersController#after_reactivate.
  private def after_deactivate
    return unless @user.idp_deactivate! == :identity_missing

    flash[:alert] = "#{@user.name} has no identity on file in the identity provider, so nothing " \
                    'was disabled there. Check whether an account still exists for them.'
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

  private def render_missing_connector
    @user = User.new(new_user_params)
    @user.errors.add(:connector_id, 'must be chosen')
    flash.now[:error] = 'Please review the form problems below'
    render :new
  end

  private def creation_notice(user, emailed:)
    parts = ["Account created for #{user.email}."]
    parts << 'A setup email has been sent.' if emailed
    parts << 'Assign roles and access below.'
    parts.join(' ')
  end

  # Active configs that can actually provision accounts; a deployment may have several, one per
  # realm, or none. A config without a management API is filtered out rather than offered, since
  # choosing it would create the account locally anyway. Empty under Devise: provisioning relies on
  # Idp::Support, which is only mixed into the user models under AuthMethod.jwt?.
  private def available_connectors
    @available_connectors ||= ::Idp::ServiceConfig.active.order(:name, :id).
      select { |config| config.to_service.supports_user_creation? }
  end

  private def set_connectors
    @connectors = available_connectors
  end

  private def local_only_connector
    LOCAL_ONLY_CONNECTOR
  end

  # Constrained to available_connectors so the connector_id param can't target an arbitrary or
  # creation-incapable config. LOCAL_ONLY_CONNECTOR — and anything else unrecognized — means no
  # remote account is provisioned.
  private def create_connector_id
    chosen = new_user_params[:connector_id]
    available_connectors.map(&:connector_id).include?(chosen) ? chosen : nil
  end

  private def new_user_params
    params.require(:user).permit(:first_name, :last_name, :email, :agency_id, :connector_id)
  end
end
