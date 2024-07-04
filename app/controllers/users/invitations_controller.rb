###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::InvitationsController < Devise::InvitationsController
  prepend_before_action :require_can_edit_users!, only: [:new, :create]
  include ViewableEntities # TODO: START_ACL remove when ACL transition complete

  # GET /resource/invitation/new
  def new
    @agencies = Agency.order(:name)
    user_options = {}
    user_options[:permission_context] = 'acls' if User.anyone_using_acls?
    @user = User.new(user_options)
  end

  def confirm
    @user = User.new
    create unless creating_admin?
  end

  # POST /resource/invitation
  def create
    if creating_admin? && current_user.confirm_password_for_admin_actions? && !current_user.valid_password?(confirmation_params[:confirmation_password])
      flash[:error] = 'User not updated. Incorrect password'
      @user = User.new
      render :confirm
      return
    end

    @user = User.with_deleted.find_by_email(invite_params[:email]).restore if User.with_deleted.find_by_email(invite_params[:email]).present?
    @user = User.invite!(invite_params.except(:legacy_role_ids), current_user) do |u|
      u.skip_invitation = invite_params[:skip_invitation]&.to_i == 1
    end
    # Roles need to be added as a second pass
    @user.update(invite_params)
    @user&.set_viewables(viewable_params.to_h.map { |k, a| [k.to_sym, a] }.to_h) # TODO: START_ACL remove when ACL transition complete
    # if we have a user to copy user groups from, add them
    copy_user_groups if @user.using_acls?

    if resource.errors.empty?
      set_flash_message :notice, :send_instructions, email: resource.email if is_flashing_format? && resource.invitation_sent_at
      redirect_to admin_users_path
    else
      @agencies = Agency.order(:name)
      render :new
    end
  end

  private def copy_user_groups
    return unless @user
    return unless invite_params[:copy_form_id].present?

    source_user = User.active.not_system.find(invite_params[:copy_form_id].to_i)
    return unless source_user

    source_user.user_groups.each do |group|
      group.add(@user)
    end
  end

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    super
  end

  # PUT /resource/invitation
  def update
    super
  end

  # GET /resource/invitation/remove?invitation_token=abcdef
  def destroy
    super
  end

  private

  def invite_params
    params.require(:user).permit(
      :last_name,
      :first_name,
      :email,
      :phone,
      :agency_id,
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

  # TODO: START_ACL remove when ACL transition complete
  def viewable_params
    params.require(:user).permit(
      data_sources: [],
      organizations: [],
      projects: [],
      reports: [],
      cohorts: [],
      project_groups: [],
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
