###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StartDateDq::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include BaseFilters
    include Filter::FilterScopes

    before_action :set_report
    before_action :set_title

    def index
      respond_to do |format|
        format.html do
          if params[:filter].present?
            data = @report.data
            @pagy, @enrollments = pagy(data, items: 50)
          end
        end
        format.xlsx do
          @enrollments = @report.data
        end
      end
    end

    private def set_report
      @filter = filter_class.new(
        user_id: current_user.id,
        enforce_one_year_range: false,
        default_start: Date.current - 3.months,
        default_end: Date.current,
      ).set_from_params(filter_params)
      @report = report_class.new(current_user.id, @filter)
    end

    private def report_class
      StartDateDq::Report
    end

    def filter_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(filter_class.new.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_title
      @title = 'Approximate Start Date Data Quality'
    end

    private def column_names
      ['# Days Difference',
       'DateToStreetESSH',
       'Entry Date',
       'Personal ID',
       'Project',
       'Project Type']
    end
    helper_method :column_names

    private def column_values(row)
      date_to_street = row.enrollment.DateToStreetESSH
      entry_date = row.enrollment.EntryDate
      difference_in_days = (entry_date - date_to_street).to_i
      [
        difference_in_days,
        date_to_street,
        entry_date,
        row.enrollment.PersonalID,
        GrdaWarehouse::Hud::Project.confidentialize(name: row.project&.name),
        HUD.project_type_brief(row.project_type),
      ]
    end
    helper_method :column_values
  end
end
