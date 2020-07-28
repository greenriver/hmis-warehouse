###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Custom
  class DbAccessController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_credential

    def index
      @credential.provision!
      DbFirewallMaintainer.new.update!
    end

    def reset
      @credential.reprovision!
      flash[:notice] = 'Database Credentials reset.'
      redirect_to(action: :index)
    end

    private def set_credential
      @credential = DbCredential.where(user_id: current_user.id).
        first_or_create
    end
  end
end
