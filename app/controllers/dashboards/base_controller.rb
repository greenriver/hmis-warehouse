module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    before_action :set_available_months
    before_action :set_chosen_months
    before_action :set_report_months
    before_action :set_project_and_organization_ids
    before_action :set_start_date
    before_action :set_end_date

    def index
      @report = active_report_class.new(months: @report_months, organization_ids: @organization_ids, project_ids: @project_ids)
    end

    # def active
    #   @reports = selected_reports_for(active_report_class)
    #   if @reports.exists?
    #     @data = @reports.map{|r| r[:data].with_indifferent_access}
    #     # @data = data[:data]
    #     # @clients = data[:clients]
    #     # @client_count = data[:client_count]
    #     # @enrollments = data[:enrollments]
    #     # @month_name = data[:month_name]
    #     # @range = ::Filters::DateRange.new(data[:range])
    #     # @labels = data[:labels]
    #   end
    #   render layout: !request.xhr?
    # end

    # def housed
    #   @report = selected_report_for(housed_report_class)
    #   if @report.present?
    #     data = @report[:data].with_indifferent_access
    #     @ph_clients = data[:ph_clients]
    #     @ph_exits = data[:ph_exits]
    #     @buckets = data[:buckets]
    #     @all_exits_labels = data[:all_exits_labels]
    #     @start_date = data[:start_date]
    #     @end_date = data[:end_date]
    #   end
    #   render layout: !request.xhr?
    # end

    # def entered
    #   @report = selected_report_for(entered_report_class)
    #   if @report.present?
    #     data = @report[:data].with_indifferent_access
    #     @enrollments_by_type = data[:enrollments_by_type]
    #     @client_enrollment_totals_by_type = data[:client_enrollment_totals_by_type]
    #     @client_entry_totals_by_type = data[:client_entry_totals_by_type]
    #     @first_time_total_deduplicated = data[:first_time_total_deduplicated]
    #     @first_time_ever = data[:first_time_ever]
    #     @data = data[:data]
    #     @labels = data[:labels]
    #     @start_date = data[:start_date]
    #     @end_date = data[:end_date]
    #   end
    #   render layout: !request.xhr?
    # end

    def set_available_months
      @available_months ||= active_report_class.distinct.order(year: :desc, month: :desc).
        pluck(:year, :month).map do |year, month|
          date = Date.new(year, month, 1)
          [[year, month], date.strftime('%B %Y')]
        end.to_h
    end

    def set_chosen_months
      @start_month = params[:choose_report][:start_month] rescue [6.months.ago.year, 6.months.ago.month].to_s
      @end_month = params[:choose_report][:end_month] rescue [1.months.ago.year, 1.months.ago.month].to_s
    end

    def set_report_months
      start_index = @available_months.keys.index(JSON.parse(@start_month))
      end_index = @available_months.keys.index(JSON.parse(@end_month))
      @report_months = @available_months.keys.slice(end_index, start_index)
    end

    def set_start_date
      (year, month) = @report_months.last
      @start_date = Date.new(year, month, 1)
    end

    def set_end_date
      (year, month) = @report_months.first
      @end_date = Date.new(year, month, -1)
    end

    def set_project_and_organization_ids
      @organization_ids = params[:choose_report][:organization_ids].map(&:presence).compact.map(&:to_i) rescue []
      @project_ids = params[:choose_report][:project_ids].map(&:presence).compact.map(&:to_i) rescue []
    end

  end
end