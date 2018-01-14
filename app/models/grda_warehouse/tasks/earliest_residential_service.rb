module GrdaWarehouse::Tasks

  # for accelerating queries asking for clients who entered homelessness within a particular date range
  class EarliestResidentialService
    include TsqlImport
    include ArelHelper
    
    def initialize(replace_all=false)
      @replace_all = replace_all.present?
    end

    def run!
      if @replace_all
        Rails.logger.info 'Removing first residential history record for all clients'
        service_history_source.where( record_type: 'first' ).delete_all
      end

      Rails.logger.info 'Finding records to update'

      history = service_history_source.connection.select_rows(query.to_sql).map do |row|
        ::OpenStruct.new(Hash[columns.keys.zip(row)])
      end
      history_by_client_id = history.group_by(&:client_id)
      history_by_household = history.group_by{|row| [row.date, row.project_id, row.household_id]}

      values = history_by_client_id.values.map(&:first).map do |row|
         # Fix the column type, select_rows now returns all strings
        row.each do |k,v|
          row[k] = service_history_source.column_types[k.to_s].type_cast_from_database(v)
        end

        end
        {
          client_id: row.client_id.to_i,
          date: row.date,
          first_date_in_program: row.date,
          last_date_in_program: row.last_date_in_program,
          age: row.age,
          data_source_id: row.data_source_id.to_i,
          enrollment_group_id: row.enrollment_group_id,
          project_id: row.project_id,
          organization_id: row.organization_id,
          household_id: row.household_id,
          project_name: row.project_name,
          project_type: row.project_type,
          computed_project_type: row.computed_project_type,
          project_tracking_method: row.project_tracking_method,
          service_type: row.service_type,
          record_type: 'first',
          presented_as_individual: row.presented_as_individual,
          other_clients_over_25: row.other_clients_over_25,
          other_clients_under_18: row.other_clients_under_18,
          other_clients_between_18_and_25: row.other_clients_between_18_and_25,
          unaccompanied_youth: row.unaccompanied_youth,
          parenting_youth: row.parenting_youth,
          parenting_juvenile: row.parenting_juvenile,
          children_only: row.children_only,
          individual_adult: row.individual_adult,
          individual_elder: row.individual_elder,
          head_of_household: row.head_of_household,
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
        client_id: sh_t[:client_id], 
        date: sh_t[:date], 
        age: sh_t[:age], 
        data_source_id: sh_t[:data_source_id], 
        last_date_in_program: sh_t[:last_date_in_program],
        enrollment_group_id: sh_t[:enrollment_group_id],
        project_id: sh_t[:project_id],
        organization_id: sh_t[:organization_id],
        household_id: sh_t[:household_id],
        project_name: sh_t[:project_name],
        project_type: sh_t[:project_type],
        computed_project_type: sh_t[:computed_project_type],
        project_tracking_method: sh_t[:project_tracking_method],
        service_type: sh_t[:service_type],
        presented_as_individual: sh_t[:presented_as_individual],
        other_clients_over_25: sh_t[:other_clients_over_25],
        other_clients_under_18: sh_t[:other_clients_under_18],
        other_clients_between_18_and_25: sh_t[:other_clients_between_18_and_25],
        unaccompanied_youth: sh_t[:unaccompanied_youth],
        parenting_youth: sh_t[:parenting_youth],
        parenting_juvenile: sh_t[:parenting_juvenile],
        children_only: sh_t[:children_only],
        individual_adult: sh_t[:individual_adult],
        individual_elder: sh_t[:individual_elder],
        head_of_household: sh_t[:head_of_household],
      }
    end

    def projects
      GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def query
      # construct inner table to find minimum dates per client
      ct = GrdaWarehouse::Hud::Client.arel_table
      ht1 = Arel::Table.new sh_t.table_name
      ht1.table_alias = 'ht1'
      ht2 = Arel::Table.new sh_t.table_name
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
      final_query = sh_t.join(inner_table).on(
          sh_t[:client_id].eq(mdt[:client_id]).and( sh_t[:date].eq mdt[:min_date] )
        ).
        where( sh_t[:record_type].eq 'entry' ).
        where( sh_t[service_history_source.project_type_column].in projects ).
        project(*columns.values)
    end

  end

end