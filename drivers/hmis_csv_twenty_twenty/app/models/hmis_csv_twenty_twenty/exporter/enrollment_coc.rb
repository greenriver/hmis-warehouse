###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Exporter
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    include ::HmisCsvTwentyTwenty::Exporter::Shared
    setup_hud_column_access(GrdaWarehouse::Hud::EnrollmentCoc.hud_csv_headers(version: '2020'))

    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    # HouseholdID is required, but often not provided, send some sane defaults
    # Also unique the HouseholdID to a data source
    def apply_overrides row, data_source_id:
      row[:ProjectID] = project_id_from_enrollment_id(row[:EnrollmentID], data_source_id) if row[:ProjectID].blank?
      id_of_enrollment = enrollment_export_id(row[:EnrollmentID], row[:PersonalID], data_source_id)

      if row[:HouseholdID].blank?
        row[:HouseholdID] = Digest::MD5.hexdigest("e_#{data_source_id}_#{row[:ProjectID]}_#{id_of_enrollment}")
      else
        row[:HouseholdID] = Digest::MD5.hexdigest("#{data_source_id}_#{row[:ProjectID]}_#{row[:HouseholdID]}")
      end

      row[:CoCCode] = enrollment_coc_from_project_coc(row[:ProjectID], data_source_id) if row[:CoCCode].blank?

      # Required by HUD spec, not always provided 99 is not valid, but we can't really guess
      row[:DataCollectionStage] = 99 if row[:DataCollectionStage].blank?

      return row
    end

    def project_id_from_enrollment_id(enrollment_id, data_source_id)
      @project_id_from_enrollment_id ||= {}.tap do |enrollments|
        GrdaWarehouse::Hud::Enrollment.
          pluck(:EnrollmentID, :data_source_id, :ProjectID).
          each do |e_id, ds_id, p_id|
            enrollments[[e_id, ds_id]] = p_id
          end
      end
      @project_id_from_enrollment_id[[enrollment_id, data_source_id]]
    end
  end
end
