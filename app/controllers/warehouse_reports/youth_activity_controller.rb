###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthActivityController < ApplicationController
    include AjaxModalRails::Controller

    before_action :set_filter

    def index
      client_ids = []
      client_ids += intakes_in_range.distinct.pluck(:client_id)
      client_ids += dfa_in_range.distinct.pluck(:client_id)
      client_ids += case_management_in_range.distinct.pluck(:client_id)
      client_ids += follow_ups_in_range.distinct.pluck(:client_id)
      client_ids += referrals_in_range.distinct.pluck(:client_id)
      @clients = GrdaWarehouse::Hud::Client.where(id: client_ids).
        preload(
          youth_intakes: [:user],
          case_managements: [:user],
          direct_financial_assistances: [:user],
          youth_referrals: [:user],
          youth_follow_ups: [:user],
        )
    end

    private def intakes_in_range
      GrdaWarehouse::YouthIntake::Base.where(updated_at: @filter.range)
    end

    private def dfa_in_range
      GrdaWarehouse::Youth::DirectFinancialAssistance.where(updated_at: @filter.range)
    end

    private def case_management_in_range
      GrdaWarehouse::Youth::YouthCaseManagement.where(updated_at: @filter.range)
    end

    private def follow_ups_in_range
      GrdaWarehouse::Youth::YouthFollowUp.where(updated_at: @filter.range)
    end

    private def referrals_in_range
      GrdaWarehouse::Youth::YouthReferral.where(updated_at: @filter.range)
    end

    private def set_filter
      @filter = ::Filters::DateRange.new(report_params[:filter])
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
        ],
      )
    end
  end
end
