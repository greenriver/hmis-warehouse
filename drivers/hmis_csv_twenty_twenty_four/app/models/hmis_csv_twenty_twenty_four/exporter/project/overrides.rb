###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Project::Overrides
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

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
      row = override_project_type(row)
      row = override_continuum_project(row)
      row = calculated_pit_count(row, export: options[:export]) if options[:export].present?

      [
        { hud_field: :HousingType, override_field: :housing_type_override },
        { hud_field: :OperatingStartDate, override_field: :operating_start_date_override },
        { hud_field: :OperatingEndDate, override_field: :operating_end_date_override },
        { hud_field: :TargetPopulation, override_field: :target_population_override },
      ].each do |settings|
        row = simple_override(row, **settings)
      end

      row
    end

    def self.ensure_reasonable_name(row, confidential: false)
      if confidential && row.confidential?
        row.ProjectName = GrdaWarehouse::Hud::Project.confidential_project_name
        row.ProjectCommonName = row.ProjectName
      end
      row.ProjectName = row.ProjectName[0...200] if row.ProjectName.present?
      row.ProjectCommonName = row.ProjectName if row.ProjectCommonName.blank?
      row.ProjectCommonName = row.ProjectCommonName[0...200] if row.ProjectCommonName.present?

      row
    end

    def self.override_project_type(row)
      return row unless GrdaWarehouse::Config.get(:project_type_override)
      return row if row.computed_project_type.blank?
      return row if row.ProjectType == row.computed_project_type

      row.ProjectType = row.computed_project_type

      row
    end

    def self.override_continuum_project(row)
      # ContinuumProject can't be NULL, set to 0 if we don't know what it should be
      row.ContinuumProject ||= 0
      return row if row.hud_continuum_funded.nil?

      row.ContinuumProject = if row.hud_continuum_funded
        1
      else
        0
      end
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
