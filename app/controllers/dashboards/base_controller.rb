module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    def index
      # Census
      @census_start_date = '2015-07-01'.to_date
      @census_end_date = 1.weeks.ago.to_date

      @months = months
      @selected = selected_report_id
    end

    def active
      @report = selected_report_for(active_report_class)
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
      @report = selected_report_for(housed_report_class)
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
      @report = selected_report_for(entered_report_class)
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

    def months
      months = {}
      active_report_class.ordered.select(:id, :parameters).index_by(&:parameters).each do | key, report |
        report.set_date_range
        start_date = report.range.start
        months[report.id] = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year}"
      end
      months
    end

    def selected_report_id
      params[:choose_report][:month].to_i rescue id_of_most_recent_report
    end

    def id_of_most_recent_report
      # assumes that newer reports have higher ids -- may not hold on dev
      months.max_by {|k, v| k}[0] # id is key of the map
    end

    def selected_report_for (report_class)
       selected_report = active_report_class.find(selected_report_id)
      report_class.where(
          created_at: [selected_report.created_at.beginning_of_day..selected_report.created_at.end_of_day])
          .limit(1).first
    end
  end
end