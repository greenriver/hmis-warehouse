###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard
  class Entered < GrdaWarehouse::WarehouseReports::Dashboard::Base
    include ArelHelper
    include ApplicationHelper

    def self.params
      start = 1.months.ago.beginning_of_month.to_date
      # unless Rails.env.production?
      #   start = 6.months.ago.beginning_of_month.to_date
      # end
      {
        start: start,
        end: 1.months.ago.end_of_month.to_date,
      }
    end

    def set_date_range
      start_date = parameters.with_indifferent_access[:start]
      end_date = parameters.with_indifferent_access[:end]
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})
      @month_name = @range.start.to_time.strftime('%B')
    end

    def init
      set_date_range()

      # build hashes suitable for chartjs
      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.sort_by(&:first)
      @data = setup_data_structure(start_date: @range.start)
      @first_time_client_ids = Set.new
    end

    def run!
      init()

      # fetch active client counts
      @client_enrollment_totals_by_type = @labels.map do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key]
        [project_type.first, enrollment_counts(project_type).count]
      end.to_h

      # fetch counts of new entries
      @client_entry_totals_by_type = @labels.map do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key]
        [project_type.first, entry_counts(project_type).count]
      end.to_h

      # fetch all entry dates for clients above
      # This has a side-effect of saving off the client ids for those who this is the first time in the
      # project type
      @buckets = @labels.map do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key]
        entries = entry_dates_by_client(project_type)
        [project_type.first, bucket_clients(entries)]
      end.to_h

      @first_time_ever = service_history_source.first_date.
        where(client_id: @first_time_client_ids.to_a, first_date_in_program: @range.range).
        distinct.
        pluck(:client_id)

      # ensure that the counts are in the same order as the labels
      @labels.each do |project_type_sym, _|
        @buckets.each do |project_type, bucket|
          project_type_key = ::HUD::project_type_brief(project_type).downcase.to_sym
          if project_type_sym == project_type_key
            bucket.each do |group_key, client_count|
              @data[group_key][:data] << client_count
            end
          end
        end
      end

      data = {
        client_enrollment_totals_by_type: @client_enrollment_totals_by_type,
        client_entry_totals_by_type: @client_entry_totals_by_type,
        first_time_total_deduplicated: @first_time_client_ids.count,
        first_time_ever: @first_time_ever.count,
        data: @data,
        labels: @labels,
        start_date: @range.start,
        end_date: @range.end,
      }
    end



    def bucket_clients clients
      buckets = {
        sixty_plus: 0,
        thirty_to_sixty: 0,
        less_than_thirty: 0,
        first_time: 0,
      }

      clients.each do |client_id, entry_dates|
        if entry_dates.map{|date| @range.range.include?(date)}.all?
          buckets[:first_time] += 1
          @first_time_client_ids << client_id
        else
          days = days_since_last_entry(entry_dates)
          if days < 30
            buckets[:less_than_thirty] += 1
          elsif (30..60).include?(days)
            buckets[:thirty_to_sixty] += 1
          else # days > 60
            buckets[:sixty_plus] += 1
          end
        end
      end
      buckets
    end

    def days_since_last_entry entry_dates
      entry_dates.first(2).reduce(:-).abs
    end

    def setup_data_structure start_date:
      {
        first_time: {
          label: 'First time clients in the project type',
          data: [],
          backgroundColor: '#288BE4',
        },
        less_than_thirty: {
          label: "Clients with an entry in #{@month_name} and an entry within 30 days prior to their most recent entry in #{@month_name}",
          data: [],
          backgroundColor: '#704C70',
        },
        thirty_to_sixty: {
          label: "Clients with an entry in #{@month_name} and between 30 and 60 days prior",
          data: [],
          backgroundColor: '#5672AA',
        },
        sixty_plus: {
          label: "Clients with an entry in #{@month_name} and 60+ days prior",
          data: [],
          backgroundColor: '#45789C',
        },
      }
    end

  end
end
