###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class ClientLookupsController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @filter = ::Filters::FilterBase.new(user_id: current_user.id, enforce_one_year_range: false)
      @filter.update(report_params)
      @map_enrollments = map_enrollments?
      respond_to do |format|
        format.html {}
        format.xlsx do
          @report = WarehouseReports::ClientLookups::Report.new(
            filter: @filter,
            user: current_user,
            map_enrollments: @map_enrollments,
          )
          render xlsx: 'report', filename: 'client_lookups.xlsx'
        end
      end
    end

    private def report_params
      return nil unless params[:report].present?

      params.require(:report).permit(@filter.known_params)
    end

    private def map_enrollments?
      ActiveModel::Type::Boolean.new.cast(params.dig(:report, :map_enrollments))
    end
  end
end
