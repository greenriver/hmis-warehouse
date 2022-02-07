###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Bi
  class ViewMaintainer
    include ArelHelper

    HUD_CSV_VERSION = '2020'.freeze
    NAMESPACE = 'bi'.freeze
    PG_ROLE = 'bi'.freeze
    SH_INTERVAL = '\'5 years\'::interval'.freeze
    DEMOGRAPHICS_VIEW = "\"#{NAMESPACE}_Demographics\"".freeze

    def remove_views
      safe_drop_view(view_name(GrdaWarehouse::Hud::Service))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Exit))
      safe_drop_view(view_name(GrdaWarehouse::Hud::EnrollmentCoc))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Disability))
      safe_drop_view(view_name(GrdaWarehouse::Hud::HealthAndDv))
      safe_drop_view(view_name(GrdaWarehouse::Hud::IncomeBenefit))
      safe_drop_view(view_name(GrdaWarehouse::Hud::EmploymentEducation))
      safe_drop_view(view_name(GrdaWarehouse::Hud::CurrentLivingSituation))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Event))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Assessment))
      safe_drop_view(view_name(GrdaWarehouse::Hud::AssessmentQuestion))
      safe_drop_view(view_name(GrdaWarehouse::Hud::AssessmentResult))

      safe_drop_view(view_name(GrdaWarehouse::Hud::Enrollment))

      safe_drop_view(view_name(GrdaWarehouse::Hud::Client))
      safe_drop_view(DEMOGRAPHICS_VIEW)

      safe_drop_view(view_name(GrdaWarehouse::Hud::Funder))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Inventory))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Export))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Affiliation))
      safe_drop_view(view_name(GrdaWarehouse::Hud::ProjectCoc))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Project))
      safe_drop_view(view_name(GrdaWarehouse::Hud::Organization))

      safe_drop_view(view_name(GrdaWarehouse::ServiceHistoryEnrollment))
      safe_drop_view(view_name(GrdaWarehouse::ServiceHistoryService))
      safe_drop_view(view_name(GrdaWarehouse::DataSource))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::Ethnicity))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::FundingSource))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::Gender))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::LivingSituation))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::ProjectType))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::Relationship))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::TrackingMethod))
      safe_drop_view(view_name(GrdaWarehouse::Lookups::YesNoEtc))
      safe_drop_view(view_name(GrdaWarehouse::Census::ByProject))
    end

    def create_views
      # safe_create_role

      non_client_view(GrdaWarehouse::Hud::Organization)
      non_client_view(GrdaWarehouse::Hud::Project)
      non_client_view(GrdaWarehouse::Hud::ProjectCoc)
      non_client_view(GrdaWarehouse::Hud::Affiliation)
      non_client_view(GrdaWarehouse::Hud::Export)
      non_client_view(GrdaWarehouse::Hud::Inventory)
      non_client_view(GrdaWarehouse::Hud::Funder)
      non_client_view(GrdaWarehouse::Hud::Service)
      non_client_view(GrdaWarehouse::Hud::Exit)
      non_client_view(GrdaWarehouse::Hud::EnrollmentCoc)
      non_client_view(GrdaWarehouse::Hud::Disability)
      non_client_view(GrdaWarehouse::Hud::HealthAndDv)
      non_client_view(GrdaWarehouse::Hud::IncomeBenefit)
      non_client_view(GrdaWarehouse::Hud::EmploymentEducation)
      non_client_view(GrdaWarehouse::Hud::CurrentLivingSituation)
      non_client_view(GrdaWarehouse::Hud::Event)
      non_client_view(GrdaWarehouse::Hud::Assessment)
      non_client_view(GrdaWarehouse::Hud::AssessmentQuestion)
      non_client_view(GrdaWarehouse::Hud::AssessmentResult)

      safe_create_view(
        view_name(GrdaWarehouse::Hud::Client),
        sql_definition: GrdaWarehouse::Hud::Client.destination.select(de_identified_client_cols).to_sql,
      )

      safe_create_view(
        DEMOGRAPHICS_VIEW,
        sql_definition: GrdaWarehouse::Hud::Client.source.
          joins(:warehouse_client_source).
          select(de_identified_demographic_cols, :data_source_id).to_sql,
      )

      non_client_view(GrdaWarehouse::Hud::Enrollment)

      client_history_view(
        GrdaWarehouse::ServiceHistoryService.where(
          "date >= (CURRENT_DATE - #{SH_INTERVAL})",
        ),
      )
      client_history_view(
        GrdaWarehouse::ServiceHistoryEnrollment.entry.where(
          "last_date_in_program IS NULL OR last_date_in_program >= (CURRENT_DATE - #{SH_INTERVAL})",
        ),
      )
      generic_view(GrdaWarehouse::DataSource, GrdaWarehouse::DataSource.view_column_names)
      generic_view(GrdaWarehouse::Lookups::Ethnicity)
      generic_view(GrdaWarehouse::Lookups::FundingSource)
      generic_view(GrdaWarehouse::Lookups::Gender)
      generic_view(GrdaWarehouse::Lookups::LivingSituation)
      generic_view(GrdaWarehouse::Lookups::ProjectType)
      generic_view(GrdaWarehouse::Lookups::Relationship)
      generic_view(GrdaWarehouse::Lookups::TrackingMethod)
      generic_view(GrdaWarehouse::Lookups::YesNoEtc)
      generic_view(GrdaWarehouse::Census::ByProject, GrdaWarehouse::Census::ByProject.view_column_names)
    end

    def de_identified_client_cols
      model = GrdaWarehouse::Hud::Client
      hmis_cols = model.hmis_structure(version: HUD_CSV_VERSION).keys.map(&:to_sym)
      # De-identified per HMIS CSV FORMAT Specifications FY2020 – January 2020
      # https://hudhdx.info/Resources/Vendors/HMIS%20CSV%20Specifications%20FY2020%20v1.8.pdf
      # ~Page 7 HashStatus of ‘SHA-256’ (4)
      hmis_cols -= [:PersonalID, :FirstName, :MiddleName, :LastName, :NameSuffix, :NameDataQuality, :SSN, :SSNDataQuality]
      de_identified = [
        '4 as "HashStatus"',
        'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("FirstName")))::bytea), \'hex\') as "FirstName"',
        'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("MiddleName")))::bytea), \'hex\') as "MiddleName"',
        'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("LastName")))::bytea), \'hex\') as "LastName"',
        'ENCODE(SHA256(SOUNDEX(UPPER(TRIM("NameSuffix")))::bytea), \'hex\') as "NameSuffix"',
        'NameDataQuality',
        # 'LPAD(RIGHT("SSN",4),9,\'x\') as "MaskedSSN"',
        'CONCAT(RIGHT("SSN",4), ENCODE(SHA256(LPAD("SSN",9,\'x\')::bytea), \'hex\')) as "SSN"',
        'SSNDataQuality',
      ]
      [c_t[:id].as('PersonalID').to_sql, *de_identified, *hmis_cols]
    end

    def de_identified_demographic_cols
      de_identified_client_cols + [
        wc_t[:destination_id].as('client_id').to_sql,
      ]
    end

    def assessment_table
      GrdaWarehouse::Hud::Assessment.arel_table
    end

    def contains_and_not_source?(model, col)
      return false if model.hud_key.to_s == col

      model.column_names.include?(col.to_s)
    end

    def join_cols
      {
        'PersonalID' => wc_t,
        'ProjectID' => p_t,
        'OrganizationID' => o_t,
        'AssessmentID' => assessment_table,
        'EnrollmentID' => e_t,
      }
    end

    def hmis_cols(model)
      # Ignore any key or join columns, we'll replace them with primary keys
      excepts = []
      excepts << model.hud_key.to_s
      join_cols.each_key do |col|
        excepts << col if contains_and_not_source?(model, col)
      end

      # Replace columns used for joins
      cols = [model.arel_table[:id].as(model.connection.quote_column_name(model.hud_key.to_s))]
      excepts.drop(1).each do |col|
        join_col = if col == 'PersonalID' then :destination_id else :id end
        cols << join_cols[col][join_col].as(model.connection.quote_column_name(col))
      end

      cols += model.hmis_structure(version: HUD_CSV_VERSION).keys.reject do |col|
        col.to_s.in?(excepts)
      end.map do |col|
        model.arel_table[col]
      end
      cols
    end

    def generic_view(model, cols = model.column_names)
      scope = model
      scope = scope.where(model.paranoia_column.to_sym => nil) if model.paranoid?
      scope = scope.select(*cols)
      safe_create_view view_name(model.arel_table), sql_definition: scope.to_sql
    end

    def client_history_view(model)
      scope = model.joins(:client)
      scope = scope.where(model.paranoia_column.to_sym => nil) if model.paranoid?
      cols = model.view_column_names

      if cols.include?('project_id')
        scope = scope.joins(:project)
        cols.reject! { |c| c == 'project_id' }
        cols << p_t[:id].as('project_id')
      end
      if cols.include?('enrollment_group_id')
        scope = scope.joins(:enrollment)
        cols.reject! { |c| c == 'enrollment_group_id' }
        cols << e_t[:id].as('enrollment_id')
      end
      scope = scope.select(*cols)
      safe_create_view view_name(model.arel_table), sql_definition: scope.to_sql
    end

    def join_project_if_appropriate(model, query)
      return query if model.name == 'GrdaWarehouse::Hud::Project'
      return join_to_projects(query) if model.column_names.include?('ProjectID')

      query
    end

    def join_organization_if_appropriate(model, query)
      return query if model.name == 'GrdaWarehouse::Hud::Organization'
      return join_to_organizations(query) if model.column_names.include?('OrganizationID')

      query
    end

    def join_enrollment_if_appropriate(model, query)
      return join_to_exits(query).where(exit_in_range) if model.name == 'GrdaWarehouse::Hud::Enrollment'
      return join_to_enrollments(query).where(exit_in_range) if model.hud_key.to_s == 'ExitID'
      return join_to_exits_through_enrollments(query).where(exit_in_range) if model.column_names.include?('EnrollmentID')

      query
    end

    def join_destination_client_if_appropriate(model, query)
      return query if model.name == 'GrdaWarehouse::Hud::Client'
      return join_to_destination_clients(query) if model.column_names.include?('PersonalID')

      query
    end

    def join_assessment_if_appropriate(model, query)
      return query if model.name == 'GrdaWarehouse::Hud::Assessment'
      return join_to_assessments(query) if model.column_names.include?('AssessmentID')

      query
    end

    def non_client_view(model)
      query = join_project_if_appropriate(model, model.arel_table)
      query = join_organization_if_appropriate(model, query)
      query = join_enrollment_if_appropriate(model, query)
      query = join_destination_client_if_appropriate(model, query)
      query = join_assessment_if_appropriate(model, query)

      query = query.where(Arel.sql("\"DateProvided\" >= (CURRENT_DATE - #{SH_INTERVAL})")) if model.hud_key.to_s == 'ServicesID'
      cols = [
        hmis_cols(model),
        model.arel_table[:data_source_id],
      ]
      cols << source_client_table[:id].as('demographic_id') if model.column_names.include?('PersonalID')

      query = query.project(cols)
      query = query.where(model.arel_table[model.paranoia_column.to_sym].eq(nil)) if model.paranoid?

      safe_create_view view_name(model), sql_definition: query.to_sql
    end

    def view_name(model)
      "\"#{NAMESPACE}_#{model.table_name}\""
    end

    def source_client_table
      @source_client_table ||= Arel::Table.new(
        GrdaWarehouse::Hud::Client.table_name,
      ).tap { |t| t.table_alias = 'source_clients' }
    end

    def destination_client_table
      @destination_client_table ||= Arel::Table.new(
        GrdaWarehouse::Hud::Client.table_name,
      ).tap { |t| t.table_alias = 'destination_clients' }
    end

    def exit_in_range
      Arel.sql("\"Exit\".\"ExitDate\" IS NULL OR \"Exit\".\"ExitDate\" >= (CURRENT_DATE - #{SH_INTERVAL})")
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
        and(at[:EnrollmentID].eq(model[:EnrollmentID])).
        and(model[:DateDeleted].eq(nil)),
      )
    end

    def join_to_exits(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      model = GrdaWarehouse::Hud::Exit.arel_table
      table.join(model).on(
        at[:data_source_id].eq(model[:data_source_id]).
        and(at[:EnrollmentID].eq(model[:EnrollmentID])).
        and(model[:DateDeleted].eq(nil)),
      )
    end

    def join_to_exits_through_enrollments(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      en_model = GrdaWarehouse::Hud::Enrollment.arel_table
      exit_model = GrdaWarehouse::Hud::Exit.arel_table
      table.join(en_model).on(
        at[:data_source_id].eq(en_model[:data_source_id]).
        and(at[:EnrollmentID].eq(en_model[:EnrollmentID])).
        and(en_model[:DateDeleted].eq(nil)),
      ).join(exit_model, Arel::Nodes::OuterJoin).on(
        en_model[:data_source_id].eq(exit_model[:data_source_id]).
        and(en_model[:EnrollmentID].eq(exit_model[:EnrollmentID])).
        and(exit_model[:DateDeleted].eq(nil)),
      )
    end

    def join_to_destination_clients(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      table.join(source_client_table).on(
        at[:data_source_id].eq(source_client_table[:data_source_id]).
        and(at[:PersonalID].eq(source_client_table[:PersonalID])).
        and(source_client_table[:DateDeleted].eq(nil)),
      ).join(wc_t).on(
        source_client_table[:id].eq(wc_t[:source_id]),
      ).join(destination_client_table).on(
        destination_client_table[:id].eq(wc_t[:destination_id]).
        and(destination_client_table[:DateDeleted].eq(nil)),
      )
    end

    def join_to_projects(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      model = GrdaWarehouse::Hud::Project.arel_table
      table.join(model).on(
        at[:data_source_id].eq(model[:data_source_id]).
        and(at[:ProjectID].eq(model[:ProjectID])).
        and(model[:DateDeleted].eq(nil)),
      )
    end

    def join_to_organizations(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      model = GrdaWarehouse::Hud::Organization.arel_table
      table.join(model).on(
        at[:data_source_id].eq(model[:data_source_id]).
        and(at[:OrganizationID].eq(model[:OrganizationID])).
        and(model[:DateDeleted].eq(nil)),
      )
    end

    def join_to_assessments(table)
      at = if table.is_a?(Arel::SelectManager)
        table.froms.first
      else
        table
      end
      model = GrdaWarehouse::Hud::Assessment.arel_table
      table.join(model).on(
        at[:data_source_id].eq(model[:data_source_id]).
        and(at[:AssessmentID].eq(model[:AssessmentID])).
        and(model[:DateDeleted].eq(nil)),
      )
    end

    def safe_drop_view(name)
      sql = "DROP VIEW IF EXISTS #{name}"
      GrdaWarehouseBase.connection.execute(sql)
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

      GrdaWarehouseBase.connection.execute sql
    end

    def safe_create_view(name, sql_definition:)
      sql = "CREATE OR REPLACE VIEW #{name} AS #{sql_definition}"

      GrdaWarehouseBase.connection.execute sql
      sql = "GRANT SELECT ON #{name} TO #{PG_ROLE}"

      GrdaWarehouseBase.connection.execute sql
    end
  end
end
