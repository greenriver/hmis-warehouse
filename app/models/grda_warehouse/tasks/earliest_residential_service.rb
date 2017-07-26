module GrdaWarehouse::Tasks

  # for accelerating queries asking for clients who entered the system within a particular date range
  class EarliestResidentialService
    include TsqlImport
    
    def initialize(replace_all=false)
      @replace_all = replace_all.present?
    end

    def run!
      @project_type_column = :project_type
      @project_type_column = :computed_project_type if override_project_type()
      if @replace_all
        Rails.logger.info 'Removing first residential history record for all clients'
        history.where( record_type: 'first' ).delete_all
      end

      Rails.logger.info 'Finding records to update'

      ht = history.arel_table

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
        where( ht1[@project_type_column].in projects ).
        group(ht1[:client_id]).
        as(mdt.table_name)

      # find ids of relevant records (it would be better, but not *that much* better, to do this in one go, but Arel doesn't seem to be able to)
      query = ht.join(inner_table).on(
          ht[:client_id].eq(mdt[:client_id]).and( ht[:date].eq mdt[:min_date] )
        ).
        where( ht[:record_type].eq 'entry' ).
        where( ht[@project_type_column].in projects ).
        project(
          ht[:client_id], 
          ht[:date], 
          ht[:age], 
          ht[:data_source_id], 
          ht[:last_date_in_program],
          ht[:enrollment_group_id],
          ht[:project_id],
          ht[:organization_id],
          ht[:household_id],
          ht[:project_name],
          ht[@project_type_column],
          ht[:project_tracking_method],
          ht[:service_type]
        )
      values = history.connection.select_rows(query.to_sql).group_by(&:first).values.map(&:first).map do |id, date, age, data_source_id, last_date_in_program, enrollment_group_id, project_id, organization_id, household_id, project_name, project_type, project_tracking_method, service_type|
         # Fix the column type, select_rows now returns all strings
        date = GrdaWarehouse::ServiceHistory.column_types['date'].type_cast_from_database(date)
        last_date_in_program = GrdaWarehouse::ServiceHistory.column_types['last_date_in_program'].type_cast_from_database(last_date_in_program)
        age = GrdaWarehouse::ServiceHistory.column_types['age'].type_cast_from_database(age)
        project_tracking_method = GrdaWarehouse::ServiceHistory.column_types['project_tracking_method'].type_cast_from_database(project_tracking_method)
        {
          client_id: id.to_i,
          date: date,
          first_date_in_program: date,
          last_date_in_program: last_date_in_program,
          age: age,
          data_source_id: data_source_id.to_i,
          enrollment_group_id: enrollment_group_id,
          project_id: project_id,
          organization_id: organization_id,
          household_id: household_id,
          project_name: project_name,
          project_type: project_type,
          computed_project_type: project_type,
          project_tracking_method: project_tracking_method,
          service_type: service_type,
          record_type: 'first',
        }
      end

      if values.empty?
        Rails.logger.info 'No records to update'
      else
        Rails.logger.info "creating #{values.size} records in batches"
        cols = values.first.keys
        insert_batch history, cols, values.map(&:values)
      end

      Rails.logger.info 'done'
    end

    def projects
      GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
    end

    def history
      GrdaWarehouse::ServiceHistory
    end

    def override_project_type
      true
    end
  end

end