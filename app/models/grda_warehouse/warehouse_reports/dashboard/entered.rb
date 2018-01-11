module GrdaWarehouse::WarehouseReports::Dashboard
  class Entered < GrdaWarehouse::WarehouseReports::Dashboard::Base
    include ArelHelper
    include ApplicationHelper

    def self.params
      {
        start_date: 1.months.ago.beginning_of_month.to_date,
        end_date: 1.months.ago.end_of_month.to_date,
      }
    end

    def run!
      # Residential enrollments in the past 30 days
      @start_date = parameters.with_indifferent_access[:start_date].to_date
      @end_date = parameters.with_indifferent_access[:end_date].to_date

      @enrollments_by_type = entered_enrollments_by_type(start_date: @start_date, end_date: @end_date)

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
          project_type_key = ::HUD::project_type_brief(project_type).downcase.to_sym
          if project_type_sym == project_type_key
            bucket.each do |group_key, ids|
              @data[group_key][:data] << ids.size
            end
          end    
        end
      end

      data = {
        enrollments_by_type: @enrollments_by_type,
        client_enrollment_totals_by_type: @client_enrollment_totals_by_type,
        client_entry_totals_by_type: @client_entry_totals_by_type,
        first_time_total_deduplicated: @first_time_total_deduplicated,
        first_time_ever: @first_time_ever,
        data: @data,
        labels: @labels,
        start_date: @start_date,
        end_date: @end_date,
      }
    end

    def homeless_service_history_source
      scope = service_history_source.
        joins(:client, :project).
        homeless
      history_scope(scope)
    end

    # all enrollments for clients who were active during the date range
    def entered_enrollments_by_type start_date:, end_date:
      enrollments_by_type = homeless_service_history_source.entry.
        joins(:client, :organization).
        where(client_id: 
          homeless_service_history_source.
          open_between(start_date: start_date, end_date: end_date + 1.day).
          select(:client_id)
        ).
        order(date: :asc).
        pluck(*entered_columns.values).
        map do |row| 
          Hash[entered_columns.keys.zip(row)]
        end.
        group_by{ |m| m[:project_type]}
        {}.tap do |m|
          enrollments_by_type.each do |project_type, enrollments|
            clients_served = homeless_service_history_source.
              service_within_date_range(start_date: start_date, end_date: end_date + 1.day).
              where(service_history_source.project_type_column => project_type).
              distinct.
              pluck(:client_id)
            # Only include enrollments where the client had service during the range in the project type
            m[project_type] = enrollments.select{|e| clients_served.include?(e[:client_id])}.group_by{|e| e[:client_id]}
          end
        end
    end

    def client_totals_from_enrollments enrollments: 
      totals = enrollments.map do |project_type, clients| 
        [
          project_type, 
          clients.count,
        ]
      end.to_h
      # force empty results for all homeless types
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.each do |project_type|
         totals[project_type] ||= 0
      end
      totals
    end

    def entries_in_range_from_enrollments enrollments:, start_date:, end_date:
        enrollments.map do |project_type, clients|
        [
          project_type,
          clients.select do |_, enrollments|
            enrollments.map do |enrollment|
              (start_date..end_date).include?(enrollment[:first_date_in_program])
            end.any?
          end
        ]
      end.to_h
    end

    # limit enrollments to those that were open during the range
    def enrollments_ongoing_in_date_range enrollments:, start_date:, end_date:
      ongoing_enrollments = enrollments.map do |project_type, clients|
        [
          project_type,
          clients.map do |id, enrollments|
            ongoing = enrollments.select do |enrollment|
              enrollment_end = enrollment[:last_date_in_program] || Date.today
              # Excellent discussion of why this works:
              # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
              # start_date < enrollment_end && end_date > enrollment[:first_date_in_program]
              dates_overlap(start_date, end_date, enrollment[:first_date_in_program], enrollment_end)
              
            end
            [id, ongoing]
          end.select do |_, enrollments|
            enrollments.any?
          end.to_h
        ]
      end.to_h
      # force empty results for all homeless types
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.each do |project_type|
         ongoing_enrollments[project_type] ||= {}
      end
      ongoing_enrollments
    end

    def bucket_clients entries:
      buckets = {}
      entries.each do |project_type, clients|
        buckets[project_type] ||= {
          sixty_plus: {},
          thirty_to_sixty: {},
          less_than_thirty: {},
          first_time: {},
        }
        clients.each do |client_id, enrollments|
          if enrollments.count == 1
            buckets[project_type][:first_time][client_id] = enrollments
          else
            days = days_since_last_entry(enrollments)
            if days < 30
              buckets[project_type][:less_than_thirty][client_id] = enrollments
            elsif (30..60).include?(days)
              buckets[project_type][:thirty_to_sixty][client_id] = enrollments
            else # days > 60
              buckets[project_type][:sixty_plus][client_id] = enrollments
            end
          end
        end
      end
      buckets
    end

    def days_since_last_entry enrollments
      enrollments.last(2).map{|m| m[:first_date_in_program]}.reduce(:-).abs
    end

    def setup_data_structure start_date:
      month_name = start_date.to_time.strftime('%B')
      {
        first_time: {
          label: 'First time clients in the project type',
          data: [],
          backgroundColor: '#288BE4',
        },
        less_than_thirty: {
          label: "Clients with an entry in #{month_name} and an entry within 30 days prior to their most recent entry in #{month_name}",
          data: [],
          backgroundColor: '#704C70',
        },
        thirty_to_sixty: {
          label: "Clients with an entry in #{month_name} and between 30 and 60 days prior",
          data: [],
          backgroundColor: '#5672AA',
        },
        sixty_plus: {
          label: "Clients with an entry in #{month_name} and 60+ days prior",
          data: [],
          backgroundColor: '#45789C',
        },
      }
    end

    def entered_columns 
      {
        project_type: sh_t[service_history_source.project_type_column].as('project_type').to_sql, 
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql, 
        client_id: sh_t[:client_id].as('client_id').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        organization_name: o_t[:OrganizationName].as('organization_name').to_sql,
      }
    end

  end
end