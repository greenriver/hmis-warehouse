module ClientEntryCalculations
  extend ActiveSupport::Concern
  
  included do
    include ArelHelper


    def entered_columns 
      [
        :project_type, 
        :first_date_in_program,
        :last_date_in_program, 
        :client_id
      ]
    end
     
    def setup_data_structure start_date:
      month_name = start_date.to_time.strftime('%B')
      {
        first_time: {
          label: 'First time clients',
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

    def client_totals_from_enrollments enrollments: 
      enrollments.map do |project_type, clients| 
        [
          project_type, 
          clients.count,
        ]
      end.to_h
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

    def entered_enrollments_by_type start_date:, end_date:
      enrollments_by_type = homeless_service_history_source.entry.
        open_between(start_date: start_date, end_date: end_date + 1.day).
        order(date: :asc).
        pluck(*entered_columns).map do |row|
          Hash[entered_columns.zip(row)]
        end.
        group_by{ |m| m[:project_type]}
        {}.tap do |m|
          enrollments_by_type.each do |project_type, enrollments|
            m[project_type] = enrollments.group_by{|e| e[:client_id]}
          end
        end
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
          dates = enrollments.map{|en| en[:first_date_in_program]}
          if enrollments.count == 1
            buckets[project_type][:first_time][client_id] = dates
          else
            days = days_since_last_entry(enrollments)
            if days < 30
              buckets[project_type][:less_than_thirty][client_id] = dates
            elsif (30..60).include?(days)
              buckets[project_type][:thirty_to_sixty][client_id] = dates
            else # days > 60
              buckets[project_type][:sixty_plus][client_id] = dates
            end
          end
        end
      end
      buckets
    end

    def days_since_last_entry enrollments
      enrollments.last(2).map{|m| m[:first_date_in_program]}.reduce(:-).abs
    end
  end
end