###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Users::InvitationsController < ApplicationController
  prepend_before_action :require_can_edit_users!, only: [:new, :create]
  include ViewableEntities # TODO: START_ACL remove when ACL transition complete

  # GET /resource/invitation/new
  def new
    @agencies = Agency.order(:name)
    user_options = {}
    user_options[:permission_context] = 'acls' if User.anyone_using_acls?
    @user = User.new(user_options)

    # Get available IDPs that support invitations
    @available_idps = available_idps_for_invitations
    # Auto-select if only one IDP is available
    @user.connector_id = @available_idps.first&.first if @available_idps.length == 1
  end

  def confirm
    @user = User.new
    create unless creating_admin?
  end

  # POST /resource/invitation
  def create
    # create the new user account
    # If IDP supports invitations, we'll create user in IDP and send invitation
    # If IDP doesn't support invitations, we'll create a shell user and they'll be linked on first login
    @user = nil
    User.transaction do
      @user = invite_and_find_or_create_user
      raise ActiveRecord::Rollback if @user.errors.any?
    end

    # handle errors
    if @user.errors.empty?
      connector_id = selected_connector_id
      if connector_id && Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
        flash[:notice] = "User created and invitation sent to #{@user.email}" if flashing_format?
      elsif flashing_format?
        flash[:notice] = "User account created for #{@user.email}. They will be linked to their IDP on first login."
      end
      redirect_to edit_admin_user_path(@user)
    else
      @agencies = Agency.order(:name)
      @available_idps = available_idps_for_invitations
      render :new
    end
  end

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    # With JWT auth, users accept invitations through their IDP
    # This action can redirect to IDP or show instructions
    redirect_to helpers.oauth2_sign_in_path, notice: 'Please sign in to accept your invitation.'
  end

  # PUT /resource/invitation
  def update
    # With JWT auth, invitation acceptance is handled by IDP
    redirect_to helpers.oauth2_sign_in_path, notice: 'Please sign in to accept your invitation.'
  end

  # GET /resource/invitation/remove?invitation_token=abcdef
  def destroy
    # Invitation removal - can be implemented if needed
    redirect_to edit_admin_user_path(params[:user_id]), notice: 'Invitation removed.'
  end

  private

  def flashing_format?
    request.format.html?
  end

  def invite_and_find_or_create_user
    email = invite_params[:email]
    connector_id = selected_connector_id

    # Check if user already exists (including soft-deleted)
    user = User.with_deleted.find_by_email(email)
    if user
      user.restore if user.deleted?
      # User exists - if IDP supports invitations, create user in IDP if not already there
      if connector_id && Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
        # Check if user has authentication source for this IDP
        unless user.enabled_authentication_sources.exists?(connector_id: connector_id)
          # User exists locally but not in IDP - create them in IDP (IDP will send invitation)
          create_user_in_idp(user, connector_id: connector_id)
        end
        # If user already exists in IDP, IDP manages invitations - no action needed
      else
        # IDP doesn't support invitations - user will be linked on first login
        # Just ensure user is active
        user.update(active: true) unless user.active?
      end
    elsif connector_id && Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
      # Create user in IDP and send invitation
      user = create_user_with_idp(connector_id: connector_id)
    else
      # Create shell user - will be linked to IDP on first login
      user = create_shell_user
    end

    return user if user.errors.present?

    # Roles need to be added as a second pass
    user.update!(invite_params)
    user.set_viewables(viewable_params.to_h.symbolize_keys) # TODO: START_ACL remove when ACL transition complete
    # if we have a user to copy user groups from, add them
    copy_user_groups(user: user) if user.using_acls?

    user
  end

  def create_shell_user
    user = User.new(invite_params.except(:legacy_role_ids))
    user.skip_invitation = true # No invitation to send
    user.confirmed_at = nil # Will be confirmed on first login via JWT
    user.active = true

    return user unless user.valid?

    # Save user to database without creating in IDP
    user.save!

    user
  end

  def create_user_with_idp(connector_id:)
    user = User.new(invite_params.except(:legacy_role_ids))
    user.skip_invitation = invite_params[:skip_invitation]&.to_i == 1
    user.confirmed_at = nil # Will be confirmed when user accepts invitation via invite code
    user.active = true

    return user unless user.valid?

    # Get the IDP service for the selected connector_id
    idp_service = Idp::ServiceFactory.for_connector(connector_id)

    # Create user in IDP and send invitation via invite code
    begin
      # Save user to database first
      user.save!

      # Create user in IDP and create invite code (unless skipped)
      if user.skip_invitation
        # Just create user in IDP without invite code
        idp_user_data = idp_service.create_user(
          email: user.email,
          first_name: user.first_name || '',
          last_name: user.last_name || '',
          phone: user.phone,
        )

        # Create authentication source
        user.user_authentication_sources.create!(
          connector_id: connector_id,
          connector_user_id: idp_user_data['userId'],
          enabled: true,
        )
      else
        # Create user and send invitation (via invite code)
        idp_service.send_invitation(
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          phone: user.phone,
        )

        # Create authentication source with placeholder
        # The connector_user_id will be updated when user accepts invitation and logs in via JWT
        user.user_authentication_sources.create!(
          connector_id: connector_id,
          connector_user_id: user.email, # Temporary placeholder
          enabled: true,
        )
      end
    rescue Idp::ServiceError => e
      user.errors.add(:base, "Failed to create user in IDP: #{e.message}")
      Rails.logger.error "Failed to create user in IDP: #{e.message}"
    rescue StandardError => e
      user.errors.add(:base, "Failed to create user: #{e.message}")
      Rails.logger.error "Failed to create user: #{e.message}"
    end

    user
  end

  def create_user_in_idp(user, connector_id:)
    idp_service = Idp::ServiceFactory.for_connector(connector_id)

    begin
      # Create user in IDP and send invitation via invite code
      idp_service.send_invitation(
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
      )

      # Create or update authentication source
      # Note: We use email as placeholder since send_invitation doesn't return user_id directly
      # This will be updated when user accepts invitation and logs in via JWT
      user.user_authentication_sources.find_or_initialize_by(connector_id: connector_id).tap do |auth_source|
        auth_source.connector_user_id = user.email # Temporary placeholder
        auth_source.enabled = true
        auth_source.save!
      end
    rescue Idp::ServiceError => e
      Rails.logger.error "Failed to create user in IDP: #{e.message}"
      user.errors.add(:base, "Failed to create user in IDP: #{e.message}")
    end
  end

  def copy_user_groups(user:)
    return unless user
    return unless invite_params[:copy_form_id].present?

    source_user = User.active.not_system.find(invite_params[:copy_form_id].to_i)
    return unless source_user

    source_user.user_groups.each do |group|
      group.add(user)
    end
  end

  def invite_params
    params.require(:user).permit(
      :last_name,
      :first_name,
      :email,
      :phone,
      :agency_id,
      :connector_id,
      :receive_file_upload_notifications,
      :receive_account_request_notifications,
      :notify_on_vispdat_completed,
      :notify_on_client_added,
      :notify_on_anomaly_identified,
      :expired_at,
      :copy_form_id,
      :credentials,
      :exclude_from_directory,
      :exclude_phone_from_directory,
      :notify_on_new_account,
      :otp_required_for_login,
      :training_completed,
      :skip_invitation,
      :permission_context,
      user_group_ids: [],
      superset_roles: [],
      # TODO: START_ACL remove when ACL transition complete
      legacy_role_ids: [],
      access_group_ids: [],
      coc_codes: [],
      # END_ACL
      contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
    )
  end

  # Get list of available IDPs that support invitations.
  #
  # @return [Array<Array<String>>] Array of [connector_id, display_name] pairs
  def available_idps_for_invitations
    Idp::ServiceFactory.supported_idps.filter_map do |connector_id|
      if Idp::ServiceFactory.idp_supports_feature?(connector_id, :invitations)
        service = Idp::ServiceFactory.for_connector(connector_id)
        [connector_id, service.idp_name]
      end
    end
  end

  # Get the selected connector_id for invitation.
  #
  # Uses the value from params, or nil if none selected or not available.
  #
  # @return [String, nil] Selected connector_id or nil
  def selected_connector_id
    connector_id = invite_params[:connector_id]
    return nil if connector_id.blank?

    # Verify the connector_id is actually available and supports invitations
    available_ids = available_idps_for_invitations.map(&:first)
    connector_id if available_ids.include?(connector_id)
  end

  # TODO: START_ACL remove when ACL transition complete
  def viewable_params
    params.require(:user).permit(
      data_sources: [],
      organizations: [],
      projects: [],
      reports: [],
      cohorts: [],
      project_groups: [],
      project_access_groups: [],
    )
  end
  # END_ACL

  def confirmation_params
    params.require(:user).permit(
      :confirmation_password,
    )
  end

  private def assigned_acl_ids
    invite_params[:access_control_ids]&.reject(&:blank?)&.map(&:to_i) || []
  end

  private def creating_admin?
    @creating_admin ||= begin
      adming_admin = false
      # If we don't already have a role granting an admin permission, and we're assinging some
      # ACLs (with associated roles)
      if assigned_acl_ids.present?
        assigned_roles = AccessControl.where(id: assigned_acl_ids).joins(:role).distinct.pluck(Role.arel_table[:id])
        Role.where(id: assigned_roles).find_each do |role|
          # If any role we're adding is administrative, make note, and present the confirmation page
          if role.administrative?
            @admin_role_name = role.role_name
            adming_admin = true
            break
          end
        end
      end
      # TODO: START_ACL remove when ACL transition complete
      role_ids = invite_params[:legacy_role_ids]&.select(&:present?)&.map(&:to_i) || []
      role_ids.each do |id|
        role = Role.find(id)
        if role.administrative?
          @admin_role_name = role.name.humanize
          adming_admin = true
        end
      end
      # END_ACL
      adming_admin
    end
  end
end
