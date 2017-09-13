module GrdaWarehouse::Tasks

  # for accelerating queries asking for clients who entered homelessness within a particular date range
  class EarliestResidentialService
    include TsqlImport
    
    def initialize(replace_all=false)
      @replace_all = replace_all.present?
    end

    def run!
      if @replace_all
        Rails.logger.info 'Removing first residential history record for all clients'
        service_history_source.where( record_type: 'first' ).delete_all
      end

      Rails.logger.info 'Finding records to update'

      ht = service_history_source.arel_table

      # construct inner table to find minimum dates per client
      ct = GrdaWarehouse::Hud::Client.arel_table
      ht1 = Arel::Table.new ht.table_name
      ht1.table_alias = 'ht1'
      ht2 = Arel::Table.new ht.table_name
      ht2.table_alias = 'ht2'
      mdt = Arel::Table.new 'min_dates'
      at  = Arel::Table.new 'already_there'
      inner_table = ht1.
        project( ht1[:date].minimum.as('min_date'), ht1[:client_id] ).
        join( ht2, Arel::Nodes::OuterJoin ).
        on( ht1[:client_id].eq(ht2[:client_id]).and( ht2[:record_type].eq 'first' ) ).   # only consider clients *who have no first residential record*
        where( ht2[:id].eq nil ).
        where( ht1[:record_type].eq 'entry' ).
        where( ht1[service_history_source.project_type_column].in projects ).
        group(ht1[:client_id]).
        as(mdt.table_name)

      # find ids of relevant records (it would be better, but not *that much* better, to do this in one go, but Arel doesn't seem to be able to)
      query = ht.join(inner_table).on(
          ht[:client_id].eq(mdt[:client_id]).and( ht[:date].eq mdt[:min_date] )
        ).
        where( ht[:record_type].eq 'entry' ).
        where( ht[service_history_source.project_type_column].in projects ).
        project(*columns.values)
      history = service_history_source.connection.select_rows(query.to_sql).map do |row|
        ::OpenStruct.new(Hash[columns.keys.zip(row)])
      end
      history_by_client_id = history.group_by(&:client_id)
      history_by_household = history.group_by{|row| [row.date, row.project_id, row.household_id]}

      values = history_by_client_id.values.map(&:first).map do |id, date, age, data_source_id, last_date_in_program, enrollment_group_id, project_id, organization_id, household_id, project_name, project_type, project_tracking_method, service_type|
         # Fix the column type, select_rows now returns all strings
        date = service_history_source.column_types['date'].type_cast_from_database(row.date)
        last_date_in_program = service_history_source.column_types['last_date_in_program'].type_cast_from_database(row.last_date_in_program)
        age = service_history_source.column_types['age'].type_cast_from_database(row.age)
        project_tracking_method = service_history_source.column_types['project_tracking_method'].type_cast_from_database(row.project_tracking_method)
        presented_as_individual = if household_id.blank?
          true
        else
          key = [row.date, row.project_id, row.household_id]
          history_by_household[key].count > 1
        end
        {
          client_id: row.id.to_i,
          date: date,
          first_date_in_program: date,
          last_date_in_program: last_date_in_program,
          age: age,
          data_source_id: row.data_source_id.to_i,
          enrollment_group_id: row.enrollment_group_id,
          project_id: row.project_id,
          organization_id: row.organization_id,
          household_id: row.household_id,
          project_name: row.project_name,
          project_type: row.project_type,
          computed_project_type: row.project_type,
          project_tracking_method: project_tracking_method,
          service_type: row.service_type,
          record_type: 'first',
          presented_as_individual: presented_as_individual,
        }
      end

      if values.empty?
        Rails.logger.info 'No records to update'
      else
        Rails.logger.info "creating #{values.size} records in batches"
        cols = values.first.keys
        insert_batch service_history_source, cols, values.map(&:values)
      end

      Rails.logger.info 'done'
    end

    def columns
      {
        client_id: ht[:client_id], 
        date: ht[:date], 
        age: ht[:age], 
        data_source_id: ht[:data_source_id], 
        last_date_in_program: ht[:last_date_in_program],
        enrollment_group_id: ht[:enrollment_group_id],
        project_id: ht[:project_id],
        organization_id: ht[:organization_id],
        household_id: ht[:household_id],
        project_name: ht[:project_name],
        project_type: ht[service_history_source.project_type_column],
        project_tracking_method: ht[:project_tracking_method],
        service_type: ht[:service_type]
      }
    end

    def projects
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

  end

end