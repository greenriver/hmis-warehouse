###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::ClientDetails
  class ExitsController < ApplicationController
    include WarehouseReportAuthorization
    include ClientDetailReports
    extend BackgroundRenderAction

    before_action :set_limited, only: [:index]
    before_action :set_filter

    background_render_action :render_section, ::BackgroundRender::ExitClientsReportJob do
      {
        filter: @filter.for_params.to_json,
        user_id: current_user.id,
      }
    end

    def index
      @show_ph_destinations = true
      @report = report_source.new(filter: @filter, user: current_user)

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def report_source
      ExitClientReport
    end
  end
end
