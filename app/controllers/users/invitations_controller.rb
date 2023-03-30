###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::InvitationsController < Devise::InvitationsController
  prepend_before_action :require_can_edit_users!, only: [:new, :create]

  # GET /resource/invitation/new
  def new
    @agencies = Agency.order(:name)
    @user = User.new
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
    @user = User.invite!(invite_params, current_user)

    if resource.errors.empty?
      set_flash_message :notice, :send_instructions, email: resource.email if is_flashing_format? && resource.invitation_sent_at
      redirect_to admin_users_path
    else
      @agencies = Agency.order(:name)
      render :new
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
      access_control_ids: [],
      contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
    )
  end

  def confirmation_params
    params.require(:user).permit(
      :confirmation_password,
    )
  end

  private def assigned_acl_ids
    user_params[:access_control_ids]&.reject(&:blank?)&.map(&:to_i) || []
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
      adming_admin
    end
  end
end
