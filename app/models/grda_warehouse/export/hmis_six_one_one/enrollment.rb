###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Export::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Import::HMISSixOneOne::Enrollment
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Enrollment.hud_csv_headers(version: '6.11') )

    self.hud_key = :EnrollmentID

    # Setup some joins so we can include deleted relationships when appropriate
    belongs_to :client_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Client.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments

    def export! enrollment_scope:, project_scope:, path:, export:
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
        export: export
      )
    end

    # HouseholdID and RelationshipToHoH are required, but often not provided, send some sane defaults
    # Also unique the HouseholdID to a data source
    def apply_overrides row, data_source_id:
      if row[:HouseholdID].blank?
        row[:HouseholdID] = Digest::MD5.hexdigest("e_#{data_source_id}_#{row[:ProjectID]}_#{row[:EnrollmentID]}")
      else
        row[:HouseholdID] = Digest::MD5.hexdigest("#{data_source_id}_#{row[:ProjectID]}_#{(row[:HouseholdID])}")
      end
      row[:RelationshipToHoH] = 1 if row[:RelationshipToHoH].blank?
      # If the project has been overridden as PH, assume the MoveInDate
      # is the EntryDate if we don't have a MoveInDate.
      # Usually we won't have a MoveInDate because it isn't required
      # if the project type isn't PH
      if project_type_overridden_to_psh?(row[:ProjectID], data_source_id)
        row[:MoveInDate] = row[:MoveInDate].presence || row[:EntryDate]
      end
      return row
    end

  end
end