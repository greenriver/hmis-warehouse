###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class IncomesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    def index
      filter_params = { user_id: current_user.id }
      filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter = ::Filters::FilterBase.new(filter_params)

      @start_date = @filter.start
      @end_date = @filter.end

      @enrollments = enrollment_source.
        open_between(start_date: @start_date, end_date: @end_date).
        in_project(@filter.effective_project_ids).
        joins(:client, :enrollment).
        order(first_date_in_program: :asc)

      respond_to do |format|
        format.html do
          @pagy, @enrollments = pagy(@enrollments)
        end
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def headers_for_export
      headers = ['Warehouse Client ID']
      headers += ['First Name', 'Last Name'] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
      headers += GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map { |source| "#{source.to_s.titleize} at Entry"  }
      headers += GrdaWarehouse::Hud::IncomeBenefit::SOURCES.keys.map { |source| "#{source.to_s.titleize} at Update" }
      headers += [
        'Gender',
        'Race',
        'Ethnicity',
      ]
      headers
    end
    helper_method :headers_for_export

    def rows_for_export
      @enrollments.map do |record|
        row = [record.client.id]
        row += [record.client.FirstName, record.client.LastName] if ::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

        at_entry = record.enrollment.income_benefits_at_entry
        GrdaWarehouse::Hud::IncomeBenefit::SOURCES.values.each do |field|
          row << at_entry&.send(field) || field
        end
        at_update = record.enrollment.income_benefits_update.last
        GrdaWarehouse::Hud::IncomeBenefit::SOURCES.values.each do |field|
          row << at_update&.send(field) || field
        end
        row + [
          record.client.gender,
          record.client.race_description,
          HUD.ethnicity(record.client.Ethnicity),
        ]
      end
    end
    helper_method :rows_for_export

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
        ],
      )
    end

    private def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end
  end
end
