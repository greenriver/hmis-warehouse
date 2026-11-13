###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports::Cas
  class CeAssessmentsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_filter

    def index
      @report = assessment_source.new(filter: @filter)
      respond_to do |format|
        format.html do
          @clients = @report.clients.
            select(@report.columns).
            order(@report.order)
          @pagy, @clients = pagy(@clients, items: 50)
          current_user.policy_context.preload_client_dependencies(@clients.map(&:id))
        end
        format.xlsx do
          # Instantiates every row. The xlsx view iterates this same memoized relation, so this adds
          # no memory beyond what the view loads and avoids running the report query twice.
          current_user.policy_context.preload_client_dependencies(@report.clients.map(&:id))
          filename = 'CE Assessments.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def set_filter
      options = filter_params[:filter] || {}
      options[:user] = current_user
      @filter = OpenStruct.new(options)
    end

    def filter_params
      params.permit(
        filter: [
          :days_homeless,
          :no_assessment_in,
          :project_id,
          :sub_population,
        ],
      )
    end
    helper_method :filter_params

    def assessment_source
      GrdaWarehouse::WarehouseReports::Cas::CeAssessment
    end
  end
end
