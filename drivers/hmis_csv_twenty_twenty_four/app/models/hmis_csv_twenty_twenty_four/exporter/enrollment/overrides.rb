###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Enrollment::Overrides
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
      row = self.class.apply_overrides(row)

      row
    end

    def self.apply_overrides(row)
      # NOTE: RelationshipToHoH changes must come before HouseholdID
      row = fix_relationship_to_hoh(row)
      row = fix_household_id(row)
      row = assign_move_in_date(row)
      row = assign_missing_coc(row)

      row
    end

    def self.fix_relationship_to_hoh(row)
      row.RelationshipToHoH = 1 if row.RelationshipToHoH.blank? && row.HouseholdID.blank?
      row.RelationshipToHoH = 99 if row.RelationshipToHoH.blank?

      row
    end

    def self.fix_household_id(row)
      row.HouseholdID = if row.HouseholdID.blank?
        Digest::MD5.hexdigest("e_#{row.data_source_id}_#{row.ProjectID}_#{row.id}")
      else
        row.HouseholdID = Digest::MD5.hexdigest("#{row.data_source_id}_#{row.ProjectID}_#{row.HouseholdID}")
      end

      row
    end

    # If the project has been overridden as PH, assume the MoveInDate
    # is the EntryDate if we don't have a MoveInDate.
    # Usually we won't have a MoveInDate because it isn't required
    # if the project type isn't PH
    def self.assign_move_in_date(row)
      return row unless project_type_overridden_as_ph?(row)

      row.MoveInDate ||= row.EntryDate

      row
    end

    def self.project_type_overridden_as_ph?(row)
      psh_types = HudUtility2024.residential_project_type_numbers_by_code[:ph]
      existing_project_type = row.project.ProjectType
      # Not PH, no need to change
      return false unless existing_project_type.in?(psh_types)

      last_loaded_project_type = row.project.loaded_items_2024.last&.ProjectType&.to_i
      # If we don't have a previous CSV version, we can't determine if it's been overridden
      return false if last_loaded_project_type.blank?

      # If it wasn't a PH project when we loaded it, then we need to update things
      ! last_loaded_project_type.in?(psh_types)
    end

    # If the EnrollmentCoC is invalid, and there is only a single CoC associated with the project,
    # use that
    def self.assign_missing_coc(row)
      return row if row.EnrollmentCoC.in?(HudUtility2024.cocs.keys)

      coc_codes = row.project.project_cocs.pluck(:CoCCode).uniq
      row.EnrollmentCoC = coc_codes.first if coc_codes.count == 1

      row
    end
  end
end
