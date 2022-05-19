###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class EnrollmentCoc::Overrides
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    # This method gets called for each row of the kiba export
    # to enable these overrides to be applied outside of the kiba context, the overrides are written as class methods that take
    # an instance of the class, with appropriate preloads and returns an overridden version.
    # in addition, there is a single `apply_overrides` method if you want all of them
    # the `process method` will apply all overrides, and then set primary and foreign keys correctly for export
    def process(row)
      row = self.class.apply_overrides(row, export: @options[:export])

      row
    end

    def self.apply_overrides(row, export:)
      row = fix_household_id(row)
      row = replace_blank(row, hud_field: :DataCollectionStage, default_value: 99)
      row = replace_blank(row, hud_field: :CoCCode, default_value: best_coc(row, export))

      row
    end

    def self.best_coc(row, export)
      return row.CoCCode if row.CoCCode.present?

      project_cocs = if export.include_deleted || export.period_type == 1
        row.enrollment_with_deleted&.project_with_deleted&.project_cocs_with_deleted&.map(&:CoCCode)
      else
        row.enrollment&.project&.project_cocs&.map(&:CoCCode)
      end
      project_cocs.uniq!
      # If we have more than one project coc, don't guess
      return nil if project_cocs.blank? || project_cocs.count > 1

      project_cocs.first
    end

    def self.fix_household_id(row)
      row.HouseholdID = if row.HouseholdID.blank?
        Digest::MD5.hexdigest("e_#{row.data_source_id}_#{row.ProjectID}_#{row.enrollment.id}")
      else
        row.HouseholdID = Digest::MD5.hexdigest("#{row.data_source_id}_#{row.ProjectID}_#{row.HouseholdID}")
      end

      row
    end
  end
end
