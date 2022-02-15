###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class AccountRequestsController < ApplicationController
    include AjaxModalRails::Controller
    include ViewableEntities
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    before_action :set_account_request, only: [:edit, :update, :destroy]

    def index
      @account_requests = account_request_scope.
        page(params[:page]).per(25)
    end

    def edit
      @agencies = Agency.order(:name)
    end

    def update
      agency_id = account_params.dig(:agency_id)
      if agency_id.blank?
        flash[:error] = 'An agency is required to create an account'
        redirect_to(action: :index)
        return
      end

      @account_request.convert_to_user!(user: current_user, role_ids: role_ids, access_group_ids: access_group_ids)
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
        role_ids: [],
        access_group_ids: [],
      )
    end

    private def role_ids
      account_params[:role_ids].select(&:present?).map(&:to_i) || []
    end

    private def access_group_ids
      account_params[:access_group_ids].select(&:present?).map(&:to_i) || []
    end

    private def confirmation_params
      params.require(:user).permit(
        :confirmation_password,
      )
    end

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

    private def set_account_request
      @account_request = account_request_scope.find(params[:id].to_i)
    end
  end
end
