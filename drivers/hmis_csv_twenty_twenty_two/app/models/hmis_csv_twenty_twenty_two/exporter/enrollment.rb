###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include ::HmisCsvTwentyTwentyTwo::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::Enrollment.hud_csv_headers(version: '2022'))

    # Setup some joins so we can include deleted relationships when appropriate
    belongs_to :client_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Client', foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments
    belongs_to :project_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Project', foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments

    def export! enrollment_scope:, project_scope:, path:, export: # rubocop:disable Lint/UnusedMethodArgument
      case export.period_type
      when 3
        export_scope = enrollment_scope
      when 1
        export_scope = enrollment_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export,
      )
    end

    # HouseholdID and RelationshipToHoH are required, but often not provided, send some sane defaults
    # Also unique the HouseholdID to a data source
    def apply_overrides row, data_source_id:
      id_of_enrollment = enrollment_export_id(row[:EnrollmentID], row[:PersonalID], data_source_id)

      # NOTE: RelationshipToHoH changes must come before HouseholdID
      row[:RelationshipToHoH] = 1 if row[:RelationshipToHoH].blank? && row[:HouseholdID].blank?
      row[:RelationshipToHoH] = 99 if row[:RelationshipToHoH].blank?

      if row[:HouseholdID].blank?
        row[:HouseholdID] = Digest::MD5.hexdigest("e_#{data_source_id}_#{row[:ProjectID]}_#{id_of_enrollment}")
      else
        row[:HouseholdID] = Digest::MD5.hexdigest("#{data_source_id}_#{row[:ProjectID]}_#{row[:HouseholdID]}")
      end

      # Only use the first 5 of the zip
      row[:LastPermanentZIP] = row[:LastPermanentZIP].to_s[0..4] if row[:LastPermanentZIP].present?
      row[:LastPermanentCity] = row[:LastPermanentCity][0...50] if row[:LastPermanentCity]
      # If the project has been overridden as PH, assume the MoveInDate
      # is the EntryDate if we don't have a MoveInDate.
      # Usually we won't have a MoveInDate because it isn't required
      # if the project type isn't PH
      row[:MoveInDate] = row[:MoveInDate].presence || row[:EntryDate] if project_type_overridden_to_psh?(row[:ProjectID], data_source_id)
      return row
    end
  end
end
