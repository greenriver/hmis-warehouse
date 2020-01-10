###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EncountersController < ApplicationController
    include WarehouseReportAuthorization

    before_action :require_can_administer_health!

    def index
    end

    def create
    end

    def destroy
    end

    def show
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=\"encounters-#{@year}.xlsx\""
        end
      end
    end
  end
end
