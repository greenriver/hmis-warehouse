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
      # FIXME should check PROJECTID matches ENROLLMENTID
      pks_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h

      rows.each do |row|
        enrollment_pk = pks_by_enrollment_id.fetch(row_value(row, field: 'ENROLLMENTID'))
        unit_type_mper_id = row_value(row, field: 'UNITTYPEID')
        assign_next_unit(enrollment_pk, unit_type_mper_id)
      end
    end

    protected

    def model_class
      Hmis::UnitOccupancy
    end
  end
end
