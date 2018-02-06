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
          simple_export_scope = self
          if tables_to_join.any?
            simple_export_scope = simple_export_scope.joins(tables_to_join)
          end
          batch = simple_export_scope.where(id: id_group).pluck(*columns)
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
    # In addition, all HUD ids in related tables will need to use the same values, so we'll
    # need to join in other tables where appropriate
    def columns_to_pluck
      @columns_to_pluck = hud_csv_headers.map do |k|
        case k
        # Special case, we should use the destination ID so our merged client records come out
        # as one
        when :PersonalID
          wc_t = GrdaWarehouse::WarehouseClient.arel_table
          cast(wc_t[:destination_id], 'VARCHAR').as(self.connection.quote_column_name(:PersonalID)).to_sql
        when hud_key.to_sym
          arel_table[:id].as(self.connection.quote_column_name(hud_key)).to_sql
        when :ProjectEntryID
          cast(e_t[:id], 'VARCHAR').as(self.connection.quote_column_name(:ProjectEntryID)).to_sql
        when :ProjectID
          cast(p_t[:id], 'VARCHAR').as(self.connection.quote_column_name(:ProjectID)).to_sql
        when :OrganizationID
          cast(o_t[:id], 'VARCHAR').as(self.connection.quote_column_name(:OrganizationID)).to_sql
        else
          arel_table[k].as("#{k}_".to_s).to_sql
        end
      end
    end

    def tables_to_join
      @tables_to_join = []
      if hud_csv_headers.include?(:PersonalID)
        if self < GrdaWarehouse::Hud::Client
          @tables_to_join << :warehouse_client_source
        else
          @tables_to_join << {client: :warehouse_client_source} 
        end
      end
      if hud_csv_headers.include?(:ProjectEntryID)
        @tables_to_join << :enrollment unless self < GrdaWarehouse::Hud::Enrollment
      end
      if hud_csv_headers.include?(:ProjectID)
        @tables_to_join << :project unless self < GrdaWarehouse::Hud::Project 
      end
      if hud_csv_headers.include?(:OrganizationID)
        @tables_to_join << :organization unless self < GrdaWarehouse::Hud::Organization
      end
      return @tables_to_join
    end

    def export_enrollment_related! enrollment_scope:, project_scope:, path:, export:
      changed_scope = modified_within_range(range: (export.start_date..export.end_date), include_deleted: export.include_deleted)
      if export.include_deleted
        changed_scope = changed_scope.joins(enrollment_with_deleted: [:project_with_deleted, {client_with_deleted: :warehouse_client_source}]).merge(project_scope)
      else
        changed_scope = changed_scope.joins(enrollment: [:project, {client: :warehouse_client_source}]).merge(project_scope)
      end

      if export.include_deleted
        model_scope = joins(enrollment_with_deleted: [{client_with_deleted: :warehouse_client_source}]).merge(enrollment_scope)
      else
        model_scope = joins(enrollment: [:project, {client: :warehouse_client_source}]).
          where( 
            enrollment_scope.where(
              e_t[:ProjectEntryID].eq(arel_table[:ProjectEntryID]).
              and(e_t[:PersonalID].eq(arel_table[:PersonalID])).
              and(e_t[:data_source_id].eq(arel_table[:data_source_id]))
            ).exists
          )
      end
      case export.period_type
      when 4
        union_scope = from(
          arel_table.create_table_alias(
            model_scope.select(*columns_to_pluck, :id).union(changed_scope.select(*columns_to_pluck, :id)),
            table_name
          )
        )
      when 3
        union_scope = model_scope.select(*columns_to_pluck, :id)
      else
        raise NotImplementedError
      end

      if columns_to_pluck.include?(:ProjectID)
        if export.include_deleted
          union_scope = union_scope.joins(enrollment_with_deleted: :project_with_deleted)
        else
          union_scope = union_scope.joins(enrollment: :project)
        end
      end

      export_to_path(
        export_scope: union_scope, 
        path: path,
        export: export
      )

    end

    def includes_union?
      false
    end
  end
end