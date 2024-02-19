###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter::ExportConcern
  extend ActiveSupport::Concern
  included do
    include ArelHelper

    # This is for backward compatibility for tests
    def self.hud_csv_file_name
      test_exporter.file_name_for(self)
    end

    def self.hmis_class
      test_exporter.hmis_class_for(self)
    end

    def self.temp_model_name
      "#{name.demodulize}Temp"
    end

    def self.test_exporter
      raise 'Only available for testing' unless Rails.env.test?

      HmisCsvTwentyTwentyFour::Exporter::Base.new(user_id: 0, start_date: Date.yesterday, end_date: Date.current, projects: [0])
    end

    def self.simple_override(row, hud_field:, override_field:, default_value: nil)
      row[hud_field] ||= default_value if default_value.present?
      return row if override_field.blank? || row.send(override_field).blank?

      row[hud_field] = row.send(override_field)
      row
    end

    def self.replace_blank(row, hud_field:, default_value:)
      row[hud_field] ||= default_value
      row
    end

    def self.note_involved_user_ids(scope:, export:)
      u_t = GrdaWarehouse::Hud::User.arel_table

      # Note user_ids
      export.user_ids ||= Set.new
      export.user_ids += scope.distinct.joins(:user).pluck(u_t[:id])
    end

    def self.enrollment_related_join_tables(export)
      if export.include_deleted || export.period_type == 1
        { enrollment_with_deleted: [:project_with_deleted, { client_with_deleted: :warehouse_client_source }] }
      else
        { enrollment: [:project, { client: :warehouse_client_source }] }
      end
    end

    def self.project_exists_for_model(project_scope, hmis_class)
      project_scope.where(
        p_t[:ProjectID].eq(hmis_class.arel_table[:ProjectID]).
        and(p_t[:data_source_id].eq(hmis_class.arel_table[:data_source_id])),
      ).arel.exists
    end

    def self.enrollment_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.id
      else
        row.enrollment&.id
      end

      id || 'Unknown'
    end

    def self.project_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.project_with_deleted&.id
      else
        row.enrollment&.project&.id
      end

      id || 'Unknown'
    end

    def self.personal_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.client_with_deleted&.warehouse_client_source&.destination_id
      else
        row.enrollment&.client&.warehouse_client_source&.destination_id
      end

      id || 'Unknown'
    end

    def self.assessment_id(row, export)
      id = if export.include_deleted || export.period_type == 1
        row.assessment_with_deleted&.id
      else
        row.assessment&.id
      end

      id || 'Unknown'
    end

    # Don't override anything by default
    def self.csv_header_override(keys)
      keys
    end

    def process(row)
      row = assign_export_id(row)
      row = self.class.adjust_keys(row, @options[:export])
      row = enforce_lengths(row)

      row
    end

    def enforce_lengths(row)
      length_limited_columns.each do |k, opts|
        next if row[k].blank?
        next unless row[k].is_a?(String)

        # Remove returns, they aren't counted correctly in the length calculation
        row[k] = row[k].gsub("\n", ' ')
        next if row[k].length <= opts[:limit]

        row[k] = row[k][0...opts[:limit]]
      end
      row
    end

    def length_limited_columns
      @length_limited_columns ||= HmisCsvTwentyTwentyFour::Exporter::Base.hmis_class_for(self.class).hmis_configuration(version: '2024').select do |col, m|
        m.key?(:limit) && ! hashed_column?(col)
      end
    end

    # A few columns get hashed and the hash is longer than the allowed length, that's ok
    private def hashed_column?(col)
      return false unless @options[:export].hash_status == 4

      col.in?(hashed_columns)
    end

    private def hashed_columns
      [
        :FirstName,
        :MiddleName,
        :LastName,
        :SSN,
      ].freeze
    end

    def assign_export_id(row)
      row.ExportID = @options[:export].export_id
      row
    end
  end
end
