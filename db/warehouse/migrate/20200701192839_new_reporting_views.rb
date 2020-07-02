class NewReportingViews < ActiveRecord::Migration[5.2]
  PG_SCHEMA = 'bi'
  def change
    GrdaWarehouseBase.connection.execute("CREATE SCHEMA IF NOT EXISTS #{PG_SCHEMA}");

    non_client_view 'Organization'
    non_client_view 'Project'
    non_client_view 'ProjectCoC'
    non_client_view 'Affiliation'
    non_client_view 'Export'
    non_client_view 'Inventory'
    non_client_view 'Funder'

    client_view
    #TODO report_clients (holds destination client records)
    #TODO report_demographics (holds source client records)
    enrollment_view

    enrollment_info_view 'Service'
    enrollment_info_view 'Exit'
    enrollment_info_view 'EnrollmentCoC'
    enrollment_info_view 'Service'
    enrollment_info_view 'Disabilities'
    enrollment_info_view 'HealthAndDv'
    enrollment_info_view 'IncomeBenefit'
    enrollment_info_view 'EmploymentEducation'
    enrollment_info_view 'CurrentLivingSituation'
    enrollment_info_view 'Event'
    enrollment_info_view 'Assessment'


    #TODO AssessmentQuestions
    #TODO AssessmentResults

    # TODO service_history_enrollments (view can limit to where GrdaWarehouse::ServiceHistoryEnrollment.open_between(start_date: 5.years.ago, end_date: Date.current))
    # TODO service_history_services (view should limit to past 5 years)
  end

  def klass(name)
    "GrdaWarehouse::HUD::#{model}".constantize
  end

  def create_view(name, sql)
    puts "#{name}: #{sql}"
    super
  end

  def non_client_view(model)
    model = klass(model)
    at = model.arel_table
    query = at
    query = query.project('*') #TODO
    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end
    create_view view_name(model.table_name), sql_definition: query.to_sql
  end

  def enrollment_info_view(model)
    query = join_to_enrollments(join_to_enrollments(model))
    query = query.project(
      destination_client_table[:id].as('client_id'),
      enrollments_table[:id].as('enrollment_id'),
      *model.column_names.map{|col| model.arel_table[col]},
      source_client_table[:id].as('demographic_id')
    )
    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end
    create_view view_name(model.table_name), sql_definition: query.to_sql
  end

  def view_name(base)
    "#{PG_SCHEMA}.Service"
  end

  def source_client_table
    @source_client_table ||= Arel::Table.new(
      GrdaWarehouse::Hud::Client.table_name
    ).tap{ |t| t.table_alias = 'source_clients' }
  end

  def destination_client_table
    @destination_client_table ||= Arel::Table.new(
      GrdaWarehouse::Hud::Client.table_name
    ).tap{ |t| t.table_alias = 'destination_clients' }
  end

  def enrollments_table
    GrdaWarehouse::Hud::Enrollment.arel_table
  end

  def client_join_table
    GrdaWarehouse::WarehouseClient.arel_table
  end

  def join_source_and_client(table)
    at = if table.is_a?(Arel::SelectManager)
      table.froms.first
    else
      table
    end

    table.join(source_client_table).on(
      at[:data_source_id].eq(source_client_table[:data_source_id]).
      and( at[:PersonalID].eq source_client_table[:PersonalID] ).
      and( source_client_table[:DateDeleted].eq nil )
    ).join(client_join_table).on(
      source_client_table[:id].eq client_join_table[:source_id]
    ).join(destination_client_table).on(
      destination_client_table[:id].eq(client_join_table[:destination_id]).
      and( destination_client_table[:DateDeleted].eq nil )
    )
  end

  def join_to_enrollments(table)
    at = if table.is_a?(Arel::SelectManager)
      table.froms.first
    else
      table
    end
    model = GrdaWarehouse::Hud::Enrollment.arel_table
    table.join(model).on(
      at[:data_source_id].eq(model[:data_source_id]).
      and( at[:PersonalID].eq model[:PersonalID] ).
      and( model[:DateDeleted].eq nil )
    )
  end
end
