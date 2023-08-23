###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class WalkInEnrollmentUnitTypesLoader < SingleFileLoader
    def filename
      'WalkInEnrollmentUnitTypes.csv'
    end

    # defer import of unit_types
    def perform
      pks_by_enrollment_id = Hmis::Hud::Enrollment
        .open_including_wip
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id, :project_id)
        .to_h { |enrollment_id, pk, project_id| [enrollment_id, [pk, project_id]] }

      rows.each do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        enrollment_pk, project_id = pks_by_enrollment_id[enrollment_id]
        unless enrollment_pk
          log_skipped_row(row, field: 'ENROLLMENTID')
          next # early return
        end
        raise 'ProjectID/EnrollmentID mismatch' if project_id != row_value(row, field: 'PROJECTID')

        unit_type_mper_id = row_value(row, field: 'UNITTYPEID')
        unit_id = assign_next_unit(
          enrollment_pk: enrollment_pk,
          unit_type_mper_id: unit_type_mper_id,
        )
        unless unit_id
          msg = "could not assign a unit for project_id: #{project_id}, enrollment_id: #{enrollment_id}, mper_unit_type_id: #{unit_type_mper_id}"
          log_info("[#{row.context}] #{msg}")
        end
      end
    end

    protected

    def model_class
      Hmis::UnitOccupancy
    end
  end
end
