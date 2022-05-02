###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class CeAssessmentsController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @column = sort_options.map { |i| i[:column] }.detect { |c| c == params[:column] } || 'assessment_date'
      @direction = ['asc', 'desc'].detect { |c| c == params[:direction] } || 'desc'

      @clients = GrdaWarehouse::Hud::Client.
        preload(:ce_assessments).
        joins(:ce_assessments).
        merge(GrdaWarehouse::CoordinatedEntryAssessment::Base.active.visible_by?(current_user)).
        destination_visible_to(current_user)

      @clients = sort_clients(@clients, @column, @direction)

      respond_to do |format|
        format.html do
          @pagy, @clients = pagy(@clients)
        end
        format.xlsx do
          headers['Content-Disposition'] = 'attachment; filename=ce_assessments.xlsx'
        end
      end
    end

    private def sort_clients(clients, column, direction)
      case column
      when 'assessment_date'
        a_t = GrdaWarehouse::CoordinatedEntryAssessment::Base.arel_table
        clients.order(a_t[:created_at].to_sql => direction)
      when 'last_name'
        clients.order(last_name: direction, first_name: direction)
      else
        clients
      end
    end

    private def sort_options
      [
        {
          column: 'assessment_date',
          direction: :desc,
          title: 'Most Recent Assessments',
        },
        {
          column: 'assessment_date',
          direction: :asc,
          title: 'Least Recent Assessments',
        },
        {
          column: 'last_name',
          direction: :asc,
          title: 'Last name A-Z',
        },
        {
          column: 'last_name',
          direction: :desc,
          title: 'Last name Z-A',
        },
      ]
    end
    helper_method :sort_options

    private def report_params
      params.permit(
        :direction,
        :column,
      )
    end
    helper_method :report_params
  end
end
