###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Enrollment::Overrides
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
      row = self.class.apply_overrides(row)

      row
    end

    def self.apply_overrides(row)
      # NOTE: RelationshipToHoH changes must come before HouseholdID
      row = fix_relationship_to_hoh(row)
      row = fix_household_id(row)
      row = fix_last_permanent_zip(row)
      row = fix_last_permanent_city(row)
      row = assign_move_in_date(row)

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

    def self.fix_last_permanent_zip(row)
      row.LastPermanentZIP = row.LastPermanentZIP.to_s[0...5] if row.LastPermanentZIP.present?

      row
    end

    def self.fix_last_permanent_city(row)
      row.LastPermanentCity = row.LastPermanentCity.to_s[0...50] if row.LastPermanentCity.present?

      row
    end

    # If the project has been overridden as PH, assume the MoveInDate
    # is the EntryDate if we don't have a MoveInDate.
    # Usually we won't have a MoveInDate because it isn't required
    # if the project type isn't PH
    def self.assign_move_in_date(row)
      return row unless row.project.project_type_overridden_as_ph?

      row.MoveInDate ||= row.EntryDate

      row
    end
  end
end
