module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    def index
      @months = months
      @selected = selected_report_ids

    end

    def active
      @reports = selected_reports_for(active_report_class)
      if @reports.exists?
        @data = @reports.map{|r| r[:data].with_indifferent_access}
        # @data = data[:data]
        # @clients = data[:clients]
        # @client_count = data[:client_count]
        # @enrollments = data[:enrollments]
        # @month_name = data[:month_name]
        # @range = ::Filters::DateRange.new(data[:range])
        # @labels = data[:labels]
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
      active_report_class.ordered.select(:id, :parameters, :created_at).
        where(created_at:'2018-03-01'.to_date..Date.today).
        group_by(&:parameters).map{|k,reports| [k, reports.max_by(&:created_at)]}. # make sure we get the most recent
        first(36).each do | key, report |
          report.set_date_range
          start_date = report.range.start
          months[report.id] = "#{Date::MONTHNAMES[start_date.month]} #{start_date.year}"
        end
      months
    end

    def selected_report_ids

      start_month_index = months.keys.index(params[:choose_report][:start_month].to_i) rescue 5
      end_month_index = months.keys.index(params[:choose_report][:end_month].to_i) rescue 0
      if end_month_index > start_month_index
        swap = start_month_index
        start_month_index = end_month_index
        end_month_index = swap
      end
      @start_month = months.keys[start_month_index]
      @end_month = months.keys[end_month_index]
      months.keys[end_month_index..start_month_index]
    end

    def selected_reports_for (report_class)
      selected_reports = report_class.where(id: selected_report_ids)
    end
  end
end