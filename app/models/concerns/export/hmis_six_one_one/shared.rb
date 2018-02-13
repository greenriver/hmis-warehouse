require 'csv'
require 'soundex'
module Export::HMISSixOneOne::Shared
  extend ActiveSupport::Concern
  included do
    include NotifierConfig
    include ArelHelper
    
    # Date::DATE_FORMATS[:default] = "%Y-%m-%d"
    # Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    # DateTime::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"

    attr_accessor :file_path

    after_initialize do
      setup_notifier('HMIS Exporter 6.11')
    end
  end
  class_methods do
    def export_to_path export_scope:, path:, export: 
      export_path = File.join(path, file_name)
      export_id = export.export_id
      CSV.open(export_path, 'wb', {force_quotes: true}) do |csv|
        csv << clean_headers(hud_csv_headers)
        if paranoid? && export.include_deleted
          export_scope = export_scope.with_deleted
        end

        # Sometimes we're plucking directly, sometimes we're plucking from a unionized table
        # and we've already overridden the select columns, so we'll pluck the hud columns
        columns = columns_to_pluck
        if includes_union? && export.period_type == 4
          columns = hud_csv_headers
        end

        # Find all of the primary ids 
        # It is much faster to do the complicated query with correlated sub-queries once
        # and pluck the ids to conserve memory, and then go back and pull the correct records
        # by id, than it is to loop over batches that each have to re-calculate the sub-queries
        ids = export_scope.pluck(:id)
        ids.in_groups_of(100_000, false) do |id_group|
          # simple_export_scope = self
          # if tables_to_join.any?
          #   simple_export_scope = simple_export_scope.joins(tables_to_join)
          # end
          batch = self.where(id: id_group).pluck(*columns)
        # export_scope.pluck_in_batches(*columns, batch_size: 100_000) do |batch|
          cleaned_batch = batch.map do |row|
            row = Hash[hud_csv_headers.zip(row)]
            row[:ExportID] = export_id
            csv << clean_row(row: row, export: export).values
          end
        end
      end
    end

    # Override as necessary
    def clean_headers(headers)
      headers
    end

    # Override as necessary
    def clean_row(row:, export:)
      # Override source IDs with WarehouseIDs where they come from other tables
      row[:PersonalID] = client_export_id(row[:PersonalID]) if row[:PersonalID].present?
      row[:ProjectID] = project_export_id(row[:ProjectID]) if row[:ProjectID].present?
      row[:OrganizationID] = organization_export_id(row[:OrganizationID]) if row[:OrganizationID].present?
      row[:EnrollmentID] = enrollment_export_id(row[:EnrollmentID]) if row[:EnrollmentID].present?

      if export.faked_pii
        export.fake_data.fake_patterns.keys.each do |k|
          if row[k].present?
            row[k] = export.fake_data.fetch(field_name: k, real_value: row[k])
          end
        end
        row
      elsif export.hash_status == 4
        row[:FirstName] = Digest::SHA256.hexdigest(Soundex.new(row[:FirstName]).soundex) if row[:FirstName].present?
        row[:LastName] = Digest::SHA256.hexdigest(Soundex.new(row[:LastName]).soundex) if row[:LastName].present?
        row[:MiddleName] = Digest::SHA256.hexdigest(Soundex.new(row[:MiddleName]).soundex) if row[:MiddleName].present?
        if row[:SSN].present?
          padded_ssn = row[:SSN].rjust(9, 'x')
          last_four =  padded_ssn.last(4)
          digested_ssn = Digest::SHA256.hexdigest(padded_ssn)
          row[:SSN] = "#{last_four}#{digested_ssn}"
        end
        row
      else
        row
      end
    end

    # All HUD Keys will need to be replaced with our IDs to make them unique across data sources.
    def columns_to_pluck
      @columns_to_pluck = hud_csv_headers.map do |k|
        case k
        when hud_key.to_sym
          arel_table[:id].as(self.connection.quote_column_name(hud_key)).to_sql
        else
          arel_table[k].as("#{k}_".to_s).to_sql
        end
      end
    end

    def export_enrollment_related! enrollment_scope:, project_scope:, path:, export:

      case export.period_type
      when 3
        export_scope = where(enrollment_exists_for_model(enrollment_scope))
        if columns_to_pluck.include?(:DateProvided)
          export_scope = export_scope.where(arel_table[:DateProvided].lteq(export.end_date))
        end
        if columns_to_pluck.include?(:InformationDate)
          export_scope = export_scope.where(arel_table[:InformationDate].lteq(export.end_date))
        end
      when 1
        export_scope = where(enrollment_exists_for_model(enrollment_scope)).modified_within_range(range: (export.start_date..export.end_date))
      end

      if export.include_deleted || export.period_type == 1
        join_tables = {enrollment_with_deleted: [{client_with_deleted: :warehouse_client_source}]}
      else
        join_tables = {enrollment: [:project, {client: :warehouse_client_source}]}
      end

      if columns_to_pluck.include?(:ProjectID)
        if export.include_deleted || export.period_type == 1
          join_tables[:enrollment_with_deleted] << :project_with_deleted
        else
          join_tables[:enrollment] << :project
        end
      end
      export_scope = export_scope.joins(join_tables)

      export_to_path(
        export_scope: export_scope, 
        path: path, 
        export: export
      )
    end

    def export_project_related! project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = where(project_exits_for_model(project_scope))
      when 1
        export_scope = where(project_exits_for_model(project_scope)).modified_within_range(range: (export.start_date..export.end_date))
      end
      export_to_path(
        export_scope: export_scope, 
        path: path, 
        export: export
      )
    end

    def includes_union?
      false
    end

    # Load some lookup tables so we don't have
    # to join when exporting, that can be very slow
    def enrollment_export_id project_entry_id
      if self < GrdaWarehouse::Hud::Enrollment
        return project_entry_id
      end
      @enrollment_lookup ||= GrdaWarehouse::Hud::Enrollment.pluck(:ProjectEntryID, :id).to_h
      @enrollment_lookup[project_entry_id]
    end

    def project_export_id project_id
      if self < GrdaWarehouse::Hud::Project
        return project_id
      end
      @project_lookup ||= GrdaWarehouse::Hud::Project.pluck(:ProjectID, :id).to_h
      @project_lookup[project_id]
    end

    def organization_export_id organization_id
      if self < GrdaWarehouse::Hud::Organization
        return organization_id
      end
      @organization_lookup ||= GrdaWarehouse::Hud::Organization.pluck(:OrganizationID, :id).to_h
      @organization_lookup[organization_id]
    end
    
    def client_export_id personal_id
      if self < GrdaWarehouse::Hud::Client
        return personal_id
      end
      @client_lookup ||= begin
        GrdaWarehouse::Hud::Client.source.
        joins(:warehouse_client_source).
        pluck(
          :PersonalID, 
          wc_t[:destination_id].as('destination_id').to_sql
        ).to_h        
      end
      @client_lookup[personal_id]
    end

    def project_exits_for_model project_scope
      project_scope.where(
        p_t[:ProjectID].eq(arel_table[:ProjectID]).
        and(p_t[:data_source_id].eq(arel_table[:data_source_id]))
      ).exists
    end

    def enrollment_exists_for_model enrollment_scope
      enrollment_scope.where(
        e_t[:PersonalID].eq(arel_table[:PersonalID]).
        and(e_t[:ProjectEntryID].eq(arel_table[:ProjectEntryID])).
        and(e_t[:data_source_id].eq(arel_table[:data_source_id]))
      ).exists
    end
  end
end