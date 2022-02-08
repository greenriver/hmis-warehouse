###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::AccountRequestsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :require_account_requests_enabled?

  def new
    @account_request = account_request_source.new
  end

  def create
    @account_request = account_request_source.create(account_request_params.merge(status: :requested))
    flash[:notice] = "Thank you for your account request.<br />You will recieve an invitation email after the request has been approved.<br />Your invitation email will be sent to #{@account_request.email}.".html_safe if @account_request.valid?
    NotifyUser.pending_account_submitted.deliver_later
    respond_with(@account_request, location: root_path)
  end

  def account_request_params
    params.require(:account_request).permit(
      :email,
      :first_name,
      :last_name,
      :phone,
      :details,
    )
  end

  def account_request_source
    AccountRequest
  end

  private def require_account_requests_enabled?
    return true if GrdaWarehouse::Config.get(:request_account_available)

    not_authorized!
  end
end
