module Dashboards
  class BaseController < ApplicationController
    include ArelHelper
    include ClientEntryCalculations
    include ClientActiveCalculations

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    def index
      # Census
      @census_start_date = '2015-07-01'.to_date
      @census_end_date = 1.weeks.ago.to_date

    end

    def active
      raise NotImplementedError
    end

    def _active(cache_key_prefix:)
      # Active Clients
      @range = ::Filters::DateRange.new({start: 1.months.ago.beginning_of_month.to_date, end: 1.months.ago.end_of_month.to_date})
      # @range = ::Filters::DateRange.new() # one week
      @month_name = @range.start.to_time.strftime('%B')
      @enrollments = Rails.cache.fetch("#{cache_key_prefix}-enrollments", expires_in: CACHE_EXPIRY) do
        active_client_service_history(range: @range)
      end
      @clients = @enrollments.keys
      @client_count = @clients.count

      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.sort.to_h
      @data = {
        clients: {
          label: 'Client count',
          backgroundColor: '#45789C',
          data: [],
        },
        enrollments: {
          label: 'Enrollment count',
          backgroundColor: '#704C70',
          data: [],
        },
      }
      @labels.each do |key, _|
        @data[:clients][:data] << @enrollments.values.
          flatten(1).
          select do |m| 
            HUD::project_type_brief(m[:project_type]).downcase.to_sym == key
          end.map do |enrollment|
            enrollment[:client_id]
          end.uniq.count
        @data[:enrollments][:data] << @enrollments.values.
          flatten(1).
          select do |m| 
            HUD::project_type_brief(m[:project_type]).downcase.to_sym == key
          end.count
      end
      
    end

    def housed
      raise NotImplementedError
    end

    def _housed(all_exits_key:, all_exits_instance_key:, start_date: 3.years.ago.beginning_of_month.to_date)
      @start_date = start_date
      @end_date = 1.month.ago.end_of_month.to_date
      columns = [:date, :destination, :client_id]
      all_exits = Rails.cache.fetch(all_exits_key, expires_in: CACHE_EXPIRY) do
        exits_from_homelessness.
          ended_between(start_date: @start_date, end_date: @end_date + 1.day).
          order(date: :asc).
          pluck(*columns).map do |date, destination, client_id|
            destination = 99 unless HUD.valid_destinations.keys.include?(destination)
            Hash[columns.zip([date, destination, client_id])]
          end
      end

      all_destinations = all_exits.map{|m| m[:destination]}.uniq
      all_date_buckets = (@start_date...@end_date).map{|date| date.strftime('%b %Y')}.uniq;
      all_date_buckets = all_date_buckets.zip(Array.new(all_date_buckets.size, 0)).to_h
      
      @ph_clients = all_exits.select{|m| HUD.permanent_destinations.include?(m[:destination])}.map{|m| m[:client_id]}.uniq

      @buckets = {}
      
      all_destinations.each do |destination|
        label = HUD::destination(destination).to_s
        if label.is_a? Numeric
          label = HUD::destination(99)
        end
        @buckets[destination] ||= {
          source_data: all_date_buckets.deep_dup,
          label: label.truncate(45),
          backgroundColor: colorize(label),
          ph: HUD.permanent_destinations.include?(destination),
        }
      end
      
      # Count up all of the exits into buckets
      all_exits.each do |row|
        destination = row[:destination]
        date = row[:date].to_date
        @buckets[destination][:source_data][date.strftime('%b %Y')] += 1 
      end

      @all_exits_labels = @buckets.values.first[:source_data].keys
      @ph_exits = @buckets.deep_dup.select{|_,m| m[:ph]}
      
      # Add some chart.js friendly counts
      @ph_exits.each do |destination, group|
        @ph_exits[destination][:data] = group[:source_data].values
      end
      @buckets.each do |destination, group|
        @buckets[destination][:data] = group[:source_data].values
      end
    end

    def entered
      raise NotImplementedError
    end

    def _entered cache_key_prefix:
      # Residential enrollments in the past 30 days
      @start_date = 1.months.ago.beginning_of_month.to_date
      @end_date = 1.months.ago.end_of_month.to_date

      @enrollments_by_type = Rails.cache.fetch("#{cache_key_prefix}-enrollments_by_project_type", expires_in: CACHE_EXPIRY) do
        entered_enrollments_by_type start_date: @start_date, end_date: @end_date
      end

      # Summary of previous stat - all enrolled clients
      open_enrollments_by_project = enrollments_ongoing_in_date_range(enrollments: @enrollments_by_type, start_date: @start_date, end_date: @end_date)

      @client_enrollment_totals_by_type = client_totals_from_enrollments(enrollments: open_enrollments_by_project)

      @entries_in_range_by_type = entries_in_range_from_enrollments(enrollments: @enrollments_by_type, start_date: @start_date, end_date: @end_date)

      @client_entry_totals_by_type = client_totals_from_enrollments(enrollments: @entries_in_range_by_type)
      
      @buckets = bucket_clients(entries: @entries_in_range_by_type)
      @first_time_total_deduplicated = @buckets.map{|_,groups| groups[:first_time].keys}.flatten.uniq.count
      @first_time_ever = homeless_service_history_source.first_date.joins(:client).
        where(date: (@start_date..@end_date)).
        count

      # build hashes suitable for chartjs
      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.sort_by(&:first)
      @data = setup_data_structure(start_date: @start_date)

      # ensure that the counts are in the same order as the labels
      @labels.each do |project_type_sym, _|
        @buckets.each do |project_type, bucket|
          project_type_key = HUD::project_type_brief(project_type).downcase.to_sym
          if project_type_sym == project_type_key
            bucket.each do |group_key, ids|
              @data[group_key][:data] << ids.size
            end
          end    
        end
      end
    end

    private def client_source
      raise 'Implement in sub-class'
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def homeless_service_history_source
      service_history_source.
        where(service_history_source.project_type_column => 
        GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES).
        where(client_id: client_source)
    end

    def residential_service_history_source
      service_history_source.
        where(
           service_history_source.project_type_column => GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
        ).
        where(client_id: client_source)
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        where(
          service_history_source.project_type_column => GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end
  end
end