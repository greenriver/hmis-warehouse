module Dashboards
  class BaseController < ApplicationController
    include ArelHelper
    include ArelTable
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
      @range = DateRange.new({start: 1.months.ago.beginning_of_month.to_date, end: 1.months.ago.end_of_month.to_date})
      # @range = DateRange.new() # one week
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
      sh = GrdaWarehouse::ServiceHistory.arel_table
      
      columns = [:date, :destination, :client_id]
      all_exits = Rails.cache.fetch(all_exits_key, expires_in: CACHE_EXPIRY) do
        exits_from_homelessness.
          ended_between(start_date: @start_date, end_date: @end_date).
          order(date: :asc).
          pluck(*columns).map do |date, destination, client_id|
            destination = 99 unless HUD.valid_destinations.keys.include?(destination)
            Hash[columns.zip([date, destination, client_id])]
          end
      end
      first_date = all_exits.first[:date]
      last_date = all_exits.last[:date]
      
      @all_exits = Rails.cache.fetch(all_exits_instance_key, expires_in: CACHE_EXPIRY) do
        @all_exits = {}
        # all_exits = all_exits.group_by{|m| m[:destination] || 99}
        all_exits.map{|m| m[:destination]}.uniq.each do |destination|
          label = HUD::destination(destination).to_s
          if label.is_a? Numeric
            label = HUD::destination(99)
          end
          @all_exits[destination] ||= {
            source_data: Hash.new(0),
            label: label.truncate(45),
            backgroundColor: colorize(label),
            ph: HUD.permanent_destinations.include?(destination),
          }
          (first_date...last_date).each do |date|
            @all_exits[destination][:source_data]["#{date.to_time.strftime('%b')} #{date.year}"] += all_exits.select do |m|
              m[:destination] == destination && m[:date] == date
            end.count
          end
        end
        @all_exits
      end
      @all_exits_labels = @all_exits.values.first[:source_data].keys
      @ph_exits = @all_exits.deep_dup.select{|_,m| m[:ph]}
      @ph_clients = all_exits.select{|m| HUD.permanent_destinations.include?(m[:destination])}.map{|m| m[:client_id]}.uniq
      @ph_exits.each do |destination, group|
        @ph_exits[destination][:data] = group[:source_data].values
      end
      @all_exits.each do |destination, group|
        @all_exits[destination][:data] = group[:source_data].values
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

      @client_enrollment_totals_by_type = client_totals_from_enrollments(enrollments: @enrollments_by_type)

      @entries_in_range_by_type = entries_in_range_from_enrollments(enrollments: @enrollments_by_type, start_date: @start_date, end_date: @end_date)

      @client_entry_totals_by_type = client_totals_from_enrollments(enrollments: @entries_in_range_by_type)
      
      @buckets = bucket_clients(entries: @entries_in_range_by_type)
      @first_time_total_deduplicated = @buckets.map{|_,groups| groups[:first_time].keys}.flatten.uniq.count

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

    def homeless_service_history_source
      GrdaWarehouse::ServiceHistory.
        where(
          project_type: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end

    private def residential_service_history_source
      GrdaWarehouse::ServiceHistory.
        where(
          project_type: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
        ).
        where(client_id: client_source)
    end

    private def exits_from_homelessness
      GrdaWarehouse::ServiceHistory.exit.
        where(
          project_type: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end
  end
end