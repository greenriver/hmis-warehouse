###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class AccountRequestsController < ApplicationController
    include ViewableEntities
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    before_action :set_account_request, only: [:update, :destroy]

    def index
      @agencies = Agency.order(:name)
      @account_requests = account_request_scope.
        page(params[:page]).per(25)
    end

    def update
      agency_id = account_params.dig(:agency_id)
      if agency_id.blank?
        flash[:error] = 'An agency is required to create an account'
        redirect_to(action: :index)
        return
      end

      @account_request.convert_to_user!(user: current_user)
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
      )
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
