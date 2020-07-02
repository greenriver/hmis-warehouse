class NewReportingViews < ActiveRecord::Migration[5.2]
  PG_SCHEMA = 'bi'
  PG_ROLE = 'bi'
  DEMOGRAPHICS_VIEW = "\"#{PG_SCHEMA}_Demographics\""

  def safe_drop_view(name)
    sql = "DROP VIEW IF EXISTS #{name}"
    say_with_time sql do
      GrdaWarehouseBase.connection.execute sql
    end
  end


  def safe_create_role(role: PG_ROLE)
    sql = <<~SQL
      DO $$
      BEGIN
        CREATE ROLE #{role} WITH NOLOGIN;
        EXCEPTION WHEN DUPLICATE_OBJECT THEN
        RAISE NOTICE 'not creating role #{role} -- it already exists';
      END
      $$;
    SQL
    say_with_time sql do
      GrdaWarehouseBase.connection.execute sql
    end
  end

  def safe_create_view(name, sql_definition:)
    sql = "CREATE OR REPLACE VIEW #{name} AS #{sql_definition}"
    say_with_time sql do
      GrdaWarehouseBase.connection.execute sql
    end
    sql = "GRANT SELECT ON #{name} TO #{PG_ROLE}"
    say_with_time sql do
      GrdaWarehouseBase.connection.execute sql
    end
  end

  def down
    safe_drop_view view_name(GrdaWarehouse::Hud::Service)
    safe_drop_view view_name(GrdaWarehouse::Hud::Exit)
    safe_drop_view view_name(GrdaWarehouse::Hud::EnrollmentCoc)
    safe_drop_view view_name(GrdaWarehouse::Hud::Disability)
    safe_drop_view view_name(GrdaWarehouse::Hud::HealthAndDv)
    safe_drop_view view_name(GrdaWarehouse::Hud::IncomeBenefit)
    safe_drop_view view_name(GrdaWarehouse::Hud::EmploymentEducation)
    safe_drop_view view_name(GrdaWarehouse::Hud::CurrentLivingSituation)
    safe_drop_view view_name(GrdaWarehouse::Hud::Event)
    safe_drop_view view_name(GrdaWarehouse::Hud::Assessment)

    safe_drop_view view_name(GrdaWarehouse::Hud::Enrollment)

    safe_drop_view view_name(GrdaWarehouse::Hud::Client)
    safe_drop_view DEMOGRAPHICS_VIEW
    #GrdaWarehouseBase.connection.execute("DROP SCHEMA IF EXISTS #{PG_SCHEMA} CASCADE");

    safe_drop_view view_name(GrdaWarehouse::Hud::Funder)
    safe_drop_view view_name(GrdaWarehouse::Hud::Inventory)
    safe_drop_view view_name(GrdaWarehouse::Hud::Export)
    safe_drop_view view_name(GrdaWarehouse::Hud::Affiliation)
    safe_drop_view view_name(GrdaWarehouse::Hud::ProjectCoc)
    safe_drop_view view_name(GrdaWarehouse::Hud::Project)
    safe_drop_view view_name(GrdaWarehouse::Hud::Organization)
  end

  def up
    # TODO: Permissions
    #GrdaWarehouseBase.connection.execute("CREATE SCHEMA IF NOT EXISTS #{PG_SCHEMA}");
    safe_create_role

    non_client_view GrdaWarehouse::Hud::Organization
    non_client_view GrdaWarehouse::Hud::Project
    non_client_view GrdaWarehouse::Hud::ProjectCoc
    non_client_view GrdaWarehouse::Hud::Affiliation
    non_client_view GrdaWarehouse::Hud::Export
    non_client_view GrdaWarehouse::Hud::Inventory
    non_client_view GrdaWarehouse::Hud::Funder

    client_view # destination
    demographics_view # source

    safe_drop_view view_name(GrdaWarehouse::Hud::Enrollment)
    enrollments_view

    # #TODO report_clients (holds destination client records)
    # #TODO report_demographics (holds source client records)
    # enrollment_view

    enrollment_info_view GrdaWarehouse::Hud::Service
    enrollment_info_view GrdaWarehouse::Hud::Exit
    enrollment_info_view GrdaWarehouse::Hud::EnrollmentCoc
    enrollment_info_view GrdaWarehouse::Hud::Disability
    enrollment_info_view GrdaWarehouse::Hud::HealthAndDv
    enrollment_info_view GrdaWarehouse::Hud::IncomeBenefit
    enrollment_info_view GrdaWarehouse::Hud::EmploymentEducation
    enrollment_info_view GrdaWarehouse::Hud::CurrentLivingSituation
    enrollment_info_view GrdaWarehouse::Hud::Event
    enrollment_info_view GrdaWarehouse::Hud::Assessment
  end


  def client_view
    model = GrdaWarehouse::Hud::Client
    hmis_cols = model.hmis_structure(version: '2020').keys.map(&:to_sym)
    # HUD PII columns
    # De-identified per
    # HMIS CSV FORMAT Specifications FY2020 – January 2020
    # Hash Status=4 SHA256
    hmis_cols -= %i/PersonalID FirstName MiddleName LastName NameSuffix NameDataQuality SSN SSNDataQuality/
    # https://hudhdx.info/Resources/Vendors/HMIS%20CSV%20Specifications%20FY2020%20v1.1.pdf
    # Page 11 HashStatus of ‘SHA-256’ (4)
    de_identified = [
      'PersonalID',
      '4 as "HashStatus"',
      'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("FirstName")))::bytea), \'hex\') as "FirstName"',
      'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("MiddleName")))::bytea), \'hex\') as "MiddleName"',
      'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("LastName")))::bytea), \'hex\') as "LastName"',
      'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("NameSuffix")))::bytea), \'hex\') as "NameSuffix"',
      'NameDataQuality',
      #'LPAD(RIGHT("SSN",4),9,\'x\') as "MaskedSSN"',
      'CONCAT(RIGHT("SSN",4), ENCODE(SHA256(LPAD("SSN",9,\'x\')::bytea), \'hex\')) as "SSN"',
      'SSNDataQuality',
    ]
    safe_create_view view_name(model), sql_definition: model.destination.select(:id, *de_identified, *hmis_cols).to_sql
  end


  def demographics_view
    model = GrdaWarehouse::Hud::Client
    safe_create_view DEMOGRAPHICS_VIEW, sql_definition: model.source.to_sql
  end

   def enrollments_view
    model = GrdaWarehouse::Hud::Enrollment
    query = join_source_and_client(model.arel_table)
    query = query.project(
      destination_client_table[:id].as('client_id'),
      enrollments_table[:id].as('enrollment_id'),
      *model.hmis_structure(version: '2020').keys.map{|col| model.arel_table[col]},
      source_client_table[:id].as('demographic_id')
    )
    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end
    safe_create_view view_name(GrdaWarehouse::Hud::Enrollment), sql_definition: query.to_sql
  end

  def non_client_view(model)
    at = model.arel_table
    query = at
    query = query.project('*') #TODO
    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end
    safe_create_view view_name(model), sql_definition: query.to_sql
  end

  def enrollment_info_view(model)
    query = join_to_enrollments(join_source_and_client(model.arel_table))
    query = query.project(
      destination_client_table[:id].as('client_id'),
      enrollments_table[:id].as('enrollment_id'),
      *model.hmis_structure(version: '2020').keys.map{|col| model.arel_table[col]},
      source_client_table[:id].as('demographic_id')
    )
    if model.paranoid?
      query = query.where( model.arel_table[model.paranoia_column.to_sym].eq nil )
    end
    safe_create_view view_name(model), sql_definition: query.to_sql
  end

  def view_name(model)
    "\"#{PG_SCHEMA}_#{model.table_name}\""
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
