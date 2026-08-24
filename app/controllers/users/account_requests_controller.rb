###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Users::AccountRequestsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :require_account_requests_enabled?

  def new
    @account_request = account_request_source.new
  end

  def create
    @account_request = account_request_source.create(account_request_params.merge(status: :requested))
    flash[:notice] = confirmation_message(@account_request).html_safe if @account_request.valid?
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

  private def confirmation_message(account_request)
    if AuthMethod.jwt?
      "Thank you for your account request.<br />An administrator will review it, and you'll be able to sign in once it is approved."
    else
      "Thank you for your account request.<br />You will receive an invitation email after the request has been approved.<br />Your invitation email will be sent to #{account_request.email}."
    end
  end
end
