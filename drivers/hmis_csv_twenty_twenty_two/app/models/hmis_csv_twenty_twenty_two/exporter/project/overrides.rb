###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter::Project
  class Overrides
    # This method gets called for each row of the kiba export
    # to enable these overrides to be applied outside of the kiba context, the overrides are written as class methods that take
    # an instance of the class, with appropriate preloads and returns an overridden version.
    # in addition, there is a single `apply_overrides` method if you want all of them
    # the `process method` will apply all overrides, and then set primary and foreign keys correctly for export
    def process(row)
      row = self.class.apply_overrides(row)
      row.OrganizationID = row.organization&.id || 'Unknown'
      row.ProjectID = row.id

      row
    end

    def self.apply_overrides(row)
      row = override_project_type(row)

      row
    end

    # If we are not ES and overriding to ES, we need a tracking method of 0
    def self.override_project_type(row)
      return row unless GrdaWarehouse::Config.get(:project_type_override)
      return row if row.computed_project_type.blank?
      return row if row.ProjectType == row.computed_project_type

      es_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]
      # changing to ES project type, set tracking method to 0
      row.TrackingMethod = if es_types.include?(row.computed_project_type) && ! es_types.include?(row.ProjectType)
        0
        # changing from ES project type, set tracking method to nil
      elsif es_types.include?(row.ProjectType) && ! es_types.include?(row.computed_project_type)
        nil
      end
      row.ProjectType = row.computed_project_type

      row
    end
  end
end
