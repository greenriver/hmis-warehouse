###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class AccountRequestsController < ApplicationController
    include AjaxModalRails::Controller
    include ViewableEntities # TODO: START_ACL remove when ACL transition complete
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    before_action :set_account_request, only: [:edit, :update, :destroy]

    def index
      @pagy, @account_requests = pagy(account_request_scope)
    end

    def edit
      @agencies = Agency.order(:name)
    end

    def update
      @agencies = Agency.order(:name)
      agency_id = account_params.dig(:agency_id)
      if agency_id.blank?
        flash.now[:error] = 'An agency is required to create an account'
        render 'edit'

        return
      end

      @account_request.agency_id = agency_id
      # TODO: START_ACL replace when ACL transition complete
      # @account_request.convert_to_user!(access_control_ids: access_control_ids)

      @account_request.transaction do
        @account_request.convert_to_user!(user: current_user, role_ids: role_ids, access_group_ids: access_group_ids, access_control_ids: access_control_ids)
      end
      # END_ACL
      flash[:notice] = "Account created for #{@account_request.name}"
      redirect_to(action: :index)
    end

    def destroy
      @account_request.update(status: :rejected, rejected_by: current_user.id, rejected_at: Time.current)
      respond_with(@account_request, location: admin_account_requests_path)
    end

    private def account_request_scope
      AccountRequest.requested
    end

    private def account_params
      params.require(:account_request).permit(
        :agency_id,
        role_ids: [], # TODO: START_ACL remove when ACL transition complete
        access_group_ids: [], # TODO: START_ACL remove when ACL transition complete
        access_control_ids: [],
      )
    end

    private def role_ids
      account_params[:role_ids].select(&:present?).map(&:to_i) || []
    end

    private def access_group_ids
      account_params[:access_group_ids].select(&:present?).map(&:to_i) || []
    end

    private def access_control_ids
      Array(account_params[:access_control_ids]).select(&:present?).map(&:to_i)
    end

    private def confirmation_params
      params.require(:user).permit(
        :confirmation_password,
      )
    end

    # TODO: START_ACL remove when ACL transition complete
    private def viewable_params
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

    private def set_account_request
      @account_request = account_request_scope.find(params[:id].to_i)
    end
  end
end
