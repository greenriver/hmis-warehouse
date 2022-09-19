###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class HudChronicsController < ApplicationController
    include ArelHelper
    include HudChronic
    include WarehouseReportAuthorization

    before_action :load_filter
    before_action :set_sort, except: [:index, :show, :running]
    before_action :set_report, only: [:show, :destroy]

    def index
      if params[:commit].present?
        # Comment to prevent rubocop trailing if
        WarehouseReports::RunHudChronicJob.perform_later(filter_params.merge(current_user_id: current_user.id))
      end
      @jobs = Delayed::Job.jobs_for_class('RunHudChronicJob').order(run_at: :desc)
      @reports = report_source.ordered.limit(50)

      # Set default filter to prior run
      previous_report = @reports.last
      return unless filter_params.blank? && previous_report

      options = previous_report.parameters['filter'].with_indifferent_access
      @filter = @filter.class.new(options)
    end

    def show
      @clients = @report.data
      @sort_options = sort_options

      sort_clients if @clients&.any?

      respond_to do |format|
        format.html
        format.xlsx do
          filter = @report.parameters['filter']
          date = filter ? filter['on'] : ''
          headers['Content-Disposition'] = "attachment; filename=HUD Chronic Clients on #{date.to_date.strftime('%Y-%m-%d')}.xlsx"
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_hud_chronics_path)
    end

    def running
      @jobs = Delayed::Job.jobs_for_class('RunHudChronicJob').order(run_at: :desc)
      @reports = report_source.ordered.limit(50)
    end

    # Present a chart of the counts from the previous three years
    def summary
      @range = ::Filters::DateRange.new(start: 3.years.ago, end: 1.day.ago)
      @counts = chronic_source.
        where(date: @range.range)
      @counts = @counts.where(individual: true) if @filter.individual
      @counts = @counts.where(dmh: true) if @filter.dmh
      @counts = @counts.joins(:client).where(Client: { VeteranStatus: 1 }) if @filter.veteran
      @counts = @counts.group(:date).
        order(date: :asc).
        count
      render json: @counts
    end

    def report_source
      GrdaWarehouse::WarehouseReports::HudChronicReport
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private

    def set_report
      @report = report_source.find params[:id].to_i
    end

    def sort_clients
      @column, @direction = params.slice(:column, :direction).values
      if @column.nil? || @direction.nil?
        @column = 'chronic.homeless_since'
        @direction = 'desc'
      end
      chronic_sort = @column.split('.')
      @clients = @clients.sort_by do |client|
        if chronic_sort.size == 2
          client['hud_chronic'][chronic_sort.last] || ''
        else
          client[@column] || ''
        end
      end
      @clients.reverse! if @direction == 'desc'
    end

    def sort_options
      [
        { title: 'Last name A-Z', column: 'LastName', direction: 'asc' },
        { title: 'Last name Z-A', column: 'LastName', direction: 'desc' },
        { title: 'First name A-Z', column: 'FirstName', direction: 'asc' },
        { title: 'First name Z-A', column: 'FirstName', direction: 'desc' },
        { title: 'Age (asc)', column: 'age', direction: 'asc' },
        { title: 'Age (desc)', column: 'age', direction: 'desc' },
        { title: 'Homeless since (asc)', column: 'chronic.homeless_since', direction: 'asc' },
        { title: 'Homeless since (desc)', column: 'chronic.homeless_since', direction: 'desc' },
        { title: 'Days in 3 yrs (asc)', column: 'chronic.days_in_last_three_years', direction: 'asc' },
        { title: 'Days in 3 yrs (desc)', column: 'chronic.days_in_last_three_years', direction: 'desc' },
        { title: 'Months in 3 yrs (asc)', column: 'chronic.months_in_last_three_years', direction: 'asc' },
        { title: 'Months in 3 yrs (desc)', column: 'chronic.months_in_last_three_years', direction: 'desc' },
      ]
    end

    def flash_interpolation_options
      { resource_name: 'HUD Chronic Clients Report' }
    end
  end
end
