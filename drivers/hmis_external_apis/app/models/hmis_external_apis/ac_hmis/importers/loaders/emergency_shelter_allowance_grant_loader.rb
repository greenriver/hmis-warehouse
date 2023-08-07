###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
# creates CustomService and CustomDataElements
module HmisExternalApis::AcHmis::Importers::Loaders
  class EmergencyShelterAllowanceGrantLoader < CustomDataElementBaseLoader
    protected

    def build_records(rows)
      owner_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      rows.flat_map do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        owner_id = owner_id_by_enrollment_id.fetch(enrollment_id)
        [
          new_cde_record(
            value: row_value(row, field: 'REFERREDTOALLOWANCEGRANT'),
            definition_key: :esg_allowance_grant_referred,
          ),
          new_cde_record(
            value: row_value(row, field: 'RECEVIEDFUNDING'),
            definition_key: :esg_allowance_grant_received,
          ),
          new_cde_record(
            value: row_value(row, field: 'AMOUNTRECEIVED'),
            definition_key: :esg_allowance_grant_received_amount,
          ),
          new_cde_record(
            value: row_value(row, field: 'REASONNOTREFERRED'),
            definition_key: :esg_allowance_grant_reason_not_referred,
          ),
        ].compact_blank.each { |r| r[:owner_id] = owner_id }
      end
    end

    def owner_class
      Hmis::Hud::Enrollment
    end
  end
end
