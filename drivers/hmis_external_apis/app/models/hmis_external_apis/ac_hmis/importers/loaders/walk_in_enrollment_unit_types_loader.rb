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

    def perform
      records = build_records
      # destroy existing records and re-import
      enrollments = Hmis::Hud::Enrollment.where(data_source: data_source)
      model_class
        .where(enrollment_id: enrollments.select(:id))
        .destroy_all
      model_class.import(records, validate: false, batch_size: 1_000)
    end

    protected

    def build_records
      # FIXME should check PROJECTID
      # FIXME should check UNITTYPEID
      pks_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      rows.map do |row|
        enrollment_pk = pks_by_enrollment_id.fetch(row_value(row, field: 'ENROLLMENTID'))
        unit_type_id = row_value(row, field: 'UNITTYPEID')
        {
          enrollment_id: enrollment_pk,
          unit_id: project_unit_tracker.next_unit_id(enrollment_pk: enrollment_pk, unit_type_mper_id: unit_type_id),
        }
      end
    end

    def model_class
      Hmis::UnitOccupancy
    end
  end
end
