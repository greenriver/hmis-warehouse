###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Temporizing replacement for Devise::InvitationsController.
# Creates users directly without sending invitation emails.
# TODO: Replace with Keycloak setup-email flow
class Users::InvitationsController < ApplicationController
  prepend_before_action :require_can_edit_users!, only: [:new, :create]
  include ViewableEntities # TODO: START_ACL remove when ACL transition complete

  # GET /resource/invitation/new
  def new
    @agencies = Agency.order(:name)
    @system_alerts = GrdaWarehouse::AlertDefinition.system_alerts.active.order(:name)
    user_options = {}
    user_options[:permission_context] = 'acls' if User.anyone_using_acls?
    @user = User.new(user_options)
    render 'admin/users/new'
  end

  # POST /resource/invitation
  def create
    @user = nil
    User.transaction do
      @user = find_or_create_user
      raise ActiveRecord::Rollback if @user.errors.any?
    end

    if @user.errors.empty?
      flash[:notice] = "User account created for #{@user.email}."
      redirect_to edit_admin_user_path(@user)
    else
      @agencies = Agency.order(:name)
      @system_alerts = GrdaWarehouse::AlertDefinition.system_alerts.active.order(:name)
      render 'admin/users/new'
    end
  end

  private def find_or_create_user
    email = invite_params[:email]
    User.with_deleted.find_by_email(email)&.restore

    existing = User.find_by_email(email)
    if existing
      existing.errors.add(:email, 'has already been taken')
      return existing
    end

    user = User.new(invite_params.except(:legacy_role_ids, :skip_invitation, :copy_form_id))
    user.confirmed_at = Time.current
    return user unless user.save

    if invite_params[:legacy_role_ids].present?
      user.legacy_role_ids = invite_params[:legacy_role_ids].reject(&:blank?)
    end

    user.set_viewables(viewable_params.to_h.symbolize_keys) # TODO: START_ACL remove when ACL transition complete
    copy_user_groups(user: user) if user.using_acls?

    user
  end

  private def copy_user_groups(user:)
    return unless user
    return unless invite_params[:copy_form_id].present?

    source_user = User.active.not_system.find(invite_params[:copy_form_id].to_i)
    return unless source_user

    source_user.user_groups.each do |group|
      group.add(user)
    end
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
      project_access_groups: [],
    )
  end
  # END_ACL
end
