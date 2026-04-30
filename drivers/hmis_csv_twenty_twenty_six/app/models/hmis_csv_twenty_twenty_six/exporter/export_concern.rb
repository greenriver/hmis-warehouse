###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix::Exporter::ExportConcern
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

      HmisCsvTwentyTwentySix::Exporter::Base.new(user_id: 0, start_date: Date.yesterday, end_date: Date.current, projects: [0])
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

    def self.round_value(row, hud_field:, rounding:, positive:)
      return row unless row[hud_field].present?

      row[hud_field] = case rounding
      when :money
        rounded = row[hud_field].to_f.round(2)
        if positive
          rounded.positive? ? rounded : nil
        else
          rounded
        end
      when :integer
        row[hud_field].to_f.round(0) # Use to_f to round .9 to 1
      else
        row[hud_field]
      end
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

    # Converts join_tables hash to proper preload arguments
    def self.enrollment_related_preloads(export)
      join_tables = enrollment_related_join_tables(export)
      [:user, join_tables]
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
      row = sanitize_string_fields(row)
      row = enforce_lengths(row)
      row = enforce_rounding(row)

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

    def enforce_rounding(row)
      rounded_columns.each do |k, opts|
        self.class.round_value(row, hud_field: k, rounding: opts[:check], positive: opts[:positive])
      end

      row
    end

    # Remove forbidden characters from string fields and strip whitespace from the ends
    # Per the FY26 CSV specification:
    # > As of October 1, 2025, HMIS CSV exports must allow for the export of all UTF-8 characters as entered by users, with the exception of the following: < > [ ] { }
    def sanitize_string_fields(row)
      string_columns.each do |col, _|
        next unless row[col].is_a?(String)

        # Remove forbidden characters and replace multiple spaces with a single space
        row[col] = row[col].gsub(/[<>\[\]{}]/, '').gsub(/\s+/, ' ').strip
      end
      row
    end

    def length_limited_columns
      @length_limited_columns ||= hmis_configuration_for_class.select do |col, m|
        m.key?(:limit) && ! hashed_column?(col)
      end
    end

    def string_columns
      @string_columns ||= hmis_configuration_for_class.select do |_, m|
        m[:type] == :string
      end
    end

    def rounded_columns
      @rounded_columns ||= hmis_configuration_for_class.select do |_, m|
        m[:check].in?([:money, :integer])
      end
    end

    # Helper method to get hmis_configuration for both standard and custom exporters
    def hmis_configuration_for_class
      if self.class.ancestors.include?(HmisCsvTwentyTwentySix::Exporter::Custom::Base)
        # For custom exporters, call hmis_configuration directly
        self.class.hmis_configuration(version: '2026')
      else
        # For standard exporters, use the existing pattern
        hmis_class = HmisCsvTwentyTwentySix::Exporter::Base.hmis_class_for(self.class)
        return {} if hmis_class.nil?

        hmis_class.hmis_configuration(version: '2026')
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
