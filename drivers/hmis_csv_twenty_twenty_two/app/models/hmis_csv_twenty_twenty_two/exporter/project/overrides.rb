###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Project::Overrides
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
      row = self.class.apply_overrides(row, options: @options)

      row
    end

    def self.apply_overrides(row, options:)
      row = ensure_reasonable_name(row, confidential: options[:confidential])
      row = calculated_pit_count(row, export: options[:export]) if options[:export].present?
      row
    end

    def self.ensure_reasonable_name(row, confidential: false)
      if confidential && row.confidential?
        row.ProjectName = GrdaWarehouse::Hud::Project.confidential_project_name
        row.ProjectCommonName = row.ProjectName
      end
      row.ProjectCommonName = row.ProjectName if row.ProjectCommonName.blank?
      # For some reason 2022 spec limits common name to 50 chars
      row.ProjectCommonName = row.ProjectCommonName[0...50] if row.ProjectCommonName.present?

      row
    end

    def self.calculated_pit_count(row, export:)
      most_recent_pit_date = Filters::FilterBase.pit_date(export.end_date)
      row.PITCount = GrdaWarehouse::ServiceHistoryService.service_excluding_extrapolated.
        joins(service_history_enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(id: row.id)).
        where(date: most_recent_pit_date).
        distinct.
        select(:client_id).
        count || 0

      row
    end
  end
end
