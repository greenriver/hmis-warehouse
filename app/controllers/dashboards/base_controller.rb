module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 2.minutes end 
    before_action :require_can_view_censuses!
    def index
      # Census
      @census_start_date = 1.years.ago.to_date
      @census_end_date = 1.weeks.ago.to_date

    end

    def active
      raise NotImplementedError
    end

    def _active(client_cache_key:, enrollment_cache_key:, client_count_key:)
      # Active Clients
      @range = DateRange.new({start: 1.months.ago.beginning_of_month.to_date, end: 1.months.ago.end_of_month.to_date})
      # @range = DateRange.new() # one week
      
      @clients = Rails.cache.fetch(client_cache_key, expires_in: CACHE_EXPIRY) do
        active_clients(range: @range)
      end
      @enrollments = Rails.cache.fetch(enrollment_cache_key, expires_in: CACHE_EXPIRY) do
        active_client_service_history(clients: @clients, range: @range)
      end
      @client_count = Rails.cache.fetch(client_count_key, expires_in: CACHE_EXPIRY) do
        @clients.count
      end

      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES
      @data = {
        label: 'Client count',
        backgroundColor: '#45789C',
        data: [],
      }
      @labels.each do |key, _|
        @data[:data] << @enrollments.values.
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

    def _entered(enrollments_by_client_key:, seen_in_past_month_key:)
      # Residential enrollments in the past 30 days
      @start_date = 1.months.ago.beginning_of_month.to_date
      @end_date = 1.months.ago.end_of_month.to_date

      columns = [:project_type, :first_date_in_program, :first_date_served, :last_date_in_program, :client_id]

      @enrollments_by_client = Rails.cache.fetch(enrollments_by_client_key, expires_in: CACHE_EXPIRY) do
        raw_enrollments = homeless_service_history_source.
          entry.where(client_id: client_source).
          started_between(start_date: @start_date, end_date: @end_date).
          joins(client: :processed_service_history).
          order(date: :asc).
          pluck(*columns).map do |row|
          Hash[columns.zip(row)]
        end
        @enrollments_by_client = raw_enrollments.group_by{ |m| m[:client_id]}
      end      

      @enrollments = {}
      @enrollments[:new_clients] = @enrollments_by_client.select do |client_id, enrollments|
        first_date_served = enrollments.first[:first_date_served]
        entry_dates = enrollments.map{|enrollment| enrollment[:first_date_in_program]}.uniq
        # If we only have one entry date and it matches our first date served, this is our first 
        # residential enrollment
        entry_dates.size == 1 && entry_dates.first == first_date_served
      end

      non_new_clients = @enrollments_by_client.select do |client_id, enrollments|
        !@enrollments[:new_clients].include?(client_id)
      end

      seen_in_past_month = Rails.cache.fetch(seen_in_past_month_key, expires_in: CACHE_EXPIRY) do
        sh = GrdaWarehouse::ServiceHistory.arel_table
        seen_in_past_month = homeless_service_history_source.
          entry_within_date_range(start_date: 3.months.ago.to_date, end_date: 1.month.ago.to_date).
          where(client_id: non_new_clients.keys).
          where(sh[:first_date_in_program].lteq(1.month.ago)).
          joins(client: :processed_service_history).
          order(date: :asc).
          pluck(*columns).map do |row|
            Hash[columns.zip(row)]
          end.
          group_by{ |m| m[:client_id]}
      end
      @enrollments[:seen_in_past_month] = seen_in_past_month
      clients_not_seen_in_past_month = @enrollments_by_client.keys - @enrollments[:new_clients].keys - @enrollments[:seen_in_past_month].keys
      @enrollments[:not_seen_in_past_month] = @enrollments_by_client.select do |client_id, enrollments|
        clients_not_seen_in_past_month.include?(client_id)
      end
      
      # build hashes suitable for chartjs
      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES
      @data = {
        new_clients: {
          label: 'First time clients',
          data: [],
          backgroundColor: '#288BE4',
        },
        seen_in_past_month: {
          label: 'Seen in the past month',
          data: [],
          backgroundColor: '#704C70',
        },
        not_seen_in_past_month: {
          label: 'Returning after more than a month',
          data: [],
          backgroundColor: '#5672AA',
        },
      }
      ph_entries = []
      @labels.each do |key, label|
        @enrollments.each do |group, enrollments|
          @data[group][:data] << enrollments.values.flatten(1).select do |m| 
            HUD::project_type_brief(m[:project_type]).downcase.to_sym == key
          end.count
          if label == 'Permanent Housing' 
            ph_entries << enrollments.values.flatten(1).select do |m| 
              HUD::project_type_brief(m[:project_type]).downcase.to_sym == :ph
            end.count
          end
        end
      end
      @ph_entries = ph_entries.reduce(:+) || 0
    end

    private def client_source
      raise 'Implement in sub-class'
    end

    private def homeless_service_history_source
      GrdaWarehouse::ServiceHistory.
        where(
          project_type: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        )
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

    private def service_history_columns
      enrollment_table = GrdaWarehouse::Hud::Enrollment.arel_table
      ds_table = GrdaWarehouse::DataSource.arel_table
      service_history_columns = [
        :client_id, 
        :project_id, 
        :first_date_in_program, 
        :last_date_in_program, 
        :project_name, 
        :project_type, 
        :organization_id, 
        :data_source_id,
        enrollment_table[:PersonalID].as('PersonalID').to_sql,
        ds_table[:short_name].as('short_name').to_sql,
      ]
    end

    private def active_clients range: 
      sort_column = "#{GrdaWarehouse::WarehouseClientsProcessed.quoted_table_name}.first_date_served"
      sort_direction = "asc"
      served_client_ids = homeless_service_history_source.
        service_within_date_range(start_date: range.start, end_date: range.end).
        select(:client_id).distinct

      clients = client_source.
        preload(:source_clients).
        includes(:processed_service_history).
        joins(:processed_service_history).
        where(id: served_client_ids).
        order("#{sort_column} #{sort_direction}")
    end

    private def active_client_service_history clients:, range: 
      homeless_service_history_source.entry.
        open_between(start_date: range.start, end_date: range.end + 1.day).
        includes(:enrollment).
        joins(:data_source).
        where(client_id: clients.map(&:id)).
        pluck(*service_history_columns).
        map do |row|
          Hash[service_history_columns.zip(row)]
        end.
        group_by{|m| m[:client_id]}
    end
  end
end