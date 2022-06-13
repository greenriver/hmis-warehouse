###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OpenEnrollmentsNoServiceController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]

    def index
      @sort_options = sort_options
      @column = sort_column
      @direction = sort_direction

      cutoff = 30.days.ago.to_date

      open_enrollments = service_history_enrollment_source.entry.
        ongoing.bed_night
      service_in_last_30_days = service_history_enrollment_source.entry.
        ongoing.bed_night.
        with_service_between(start_date: cutoff, end_date: Date.current)
      open_enrollments_no_service = open_enrollments - service_in_last_30_days
      earliest_entry = begin
                         [open_enrollments.minimum(:first_date_in_program), 3.years.ago.to_date].max
                       rescue StandardError
                         3.years.ago.to_date
                       end
      @entries = open_enrollments_no_service
      client_ids = @entries.map(&:client_id).uniq
      @clients = client_source.where(id: client_ids).
        pluck(:id, :FirstName, :LastName).map do |row|
          Hash[[:id, :FirstName, :LastName].zip(row)]
        end.index_by { |m| m[:id] }
      @max_dates = service_history_service_source.
        where(service_history_enrollment_id: @entries.map(&:id)).
        where(date: (earliest_entry..Date.current)).
        group(:service_history_enrollment_id).
        maximum(:date)
      respond_to do |format|
        format.html do
        end
        format.xlsx do
        end
      end
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end
    private def service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).
        merge(GrdaWarehouse::Hud::Project.es.viewable_by(current_user)).
        preload(project: :organization)
    end
    private def service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end

    private def sort_column
      if sort_options.map { |m| m[:column] }.uniq.include?(params[:sort])
        params[:sort]
      else
        "#{GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name}.first_date_in_program"
      end
    end

    private def sort_direction
      ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
    end

    private def sort_options
      [
        # {
        #   title: 'Last name A-Z',
        #   column: "#{GrdaWarehouse::Hud::Client.quoted_table_name}.LastName",
        #   direction: 'asc'
        # },
        # {
        #   title: 'Last name Z-A',
        #   column: "#{GrdaWarehouse::Hud::Client.quoted_table_name}.LastName",
        #   direction: 'desc'
        # },
        {
          title: 'Project',
          column: "#{GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name}.project_name",
          direction: 'asc',
        },
        {
          title: 'Longest',
          column: "#{GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name}.first_date_in_program",
          direction: 'asc',
        },
        {
          title: 'Shortest',
          column: "#{GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name}.first_date_in_program",
          direction: 'desc',
        },
        # {
        #   title: 'Most Recently Seen',
        #   column: "max_date",
        #   direction: 'desc'
        # },
      ]
    end

    private def cols
      [
        :id,
        :enrollment_group_id,
        :data_source_id,
        :project_id,
        :organization_id,
        :project_name,
        :first_date_in_program,
        :client_id,
      ]
    end
  end
end
