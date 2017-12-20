module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    def index
      # Census
      @census_start_date = '2015-07-01'.to_date
      @census_end_date = 1.weeks.ago.to_date

    end

    def active
      @report = active_report_class.ordered.first
      if @report.present?
        data = @report[:data].with_indifferent_access
        @data = data[:data]
        @clients = data[:clients]
        @client_count = data[:client_count]
        @enrollments = data[:enrollments]
        @month_name = data[:month_name]
        @range = ::Filters::DateRange.new(data[:range])
        @labels = data[:labels]
      end
      render layout: !request.xhr?
    end

    def housed
      @report = housed_report_class.ordered.first
      if @report.present?
        data = @report[:data].with_indifferent_access
        @ph_clients = data[:ph_clients]
        @ph_exits = data[:ph_exits]
        @buckets = data[:buckets]
        @all_exits_labels = data[:all_exits_labels]
        @start_date = data[:start_date]
        @end_date = data[:end_date]
      end
      render layout: !request.xhr?
    end

    def entered
      @report = entered_report_class.ordered.first
      if @report.present?
        data = @report[:data].with_indifferent_access
        @enrollments_by_type = data[:enrollments_by_type]
        @client_enrollment_totals_by_type = data[:client_enrollment_totals_by_type]
        @client_entry_totals_by_type = data[:client_entry_totals_by_type]
        @first_time_total_deduplicated = data[:first_time_total_deduplicated]
        @first_time_ever = data[:first_time_ever]
        @data = data[:data]
        @labels = data[:labels]
        @start_date = data[:start_date]
        @end_date = data[:end_date]
      end
      render layout: !request.xhr?
    end

  end
end