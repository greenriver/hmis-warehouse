module ClientActiveCalculations
  extend ActiveSupport::Concern
  included do
    
    def service_history_columns
      {
        client_id: sh_t[:client_id].as('client_id').to_sql, 
        project_id:  sh_t[:project_id].as('project_id').to_sql, 
        first_date_in_program:  sh_t[:first_date_in_program].as('first_date_in_program').to_sql, 
        last_date_in_program:  sh_t[:last_date_in_program].as('last_date_in_program').to_sql, 
        project_name:  sh_t[:project_name].as('project_name').to_sql, 
        project_type:  sh_t[:project_type].as('project_type').to_sql, 
        organization_id:  sh_t[:organization_id].as('organization_id').to_sql, 
      }
    end

    def active_client_service_history range: 
      homeless_service_history_source.entry.
        open_between(start_date: range.start, end_date: range.end + 1.day).
        where(client_id: homeless_service_history_source.service_within_date_range(start_date: range.start, end_date: range.end + 1.day).select(:client_id)
        ).
        pluck(*service_history_columns.values).
        map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.select do |row|
          # throw out any that start after the range
          row[:first_date_in_program] <= range.end
        end.
        group_by{|m| m[:client_id]}
    end

    def homeless_service_history_source
      GrdaWarehouse::ServiceHistory.
        where(
          project_type: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        ).
        where(client_id: client_source)
    end
  end
end