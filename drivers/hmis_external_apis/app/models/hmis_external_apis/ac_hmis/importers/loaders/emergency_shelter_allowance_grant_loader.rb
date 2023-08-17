###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
module HmisExternalApis::AcHmis::Importers::Loaders
  class EmergencyShelterAllowanceGrantLoader < CustomDataElementBaseLoader
    def filename
      'EmergencyShelterAllowanceGrant.csv'
    end

    protected

    def cde_definitions_keys
      [
        :esg_allowance_grant_referred,
        :esg_allowance_grant_received,
        :esg_allowance_grant_received_amount,
        :esg_allowance_grant_reason_not_referred,
      ]
    end

    def build_records
      owner_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :id)
        .to_h
      rows.flat_map do |row|
        enrollment_id = row_value(row, field: 'ENROLLMENTID')
        owner_id = owner_id_by_enrollment_id.fetch(enrollment_id)
        [
          new_cde_record(
            value: cde_value(row_value(row, field: 'REFERREDTOALLOWANCEGRANT')),
            definition_key: :esg_allowance_grant_referred,
          ),
          new_cde_record(
            value: cde_value(row_value(row, field: 'RECEVIEDFUNDING', required: false)),
            definition_key: :esg_allowance_grant_received,
          ),
          new_cde_record(
            value: row_value(row, field: 'AMOUNTRECEIVED', required: false),
            definition_key: :esg_allowance_grant_received_amount,
          ),
          new_cde_record(
            # FIXME - need to map integer value, mapping not yet provided
            value: cde_value(row_value(row, field: 'REASONNOTREFERRED', required: false)),
            definition_key: :esg_allowance_grant_reason_not_referred,
          ),
        ].compact_blank.each { |r| r[:owner_id] = owner_id }
      end
    end

    CDE_VALUE_MAP = {
      '1' => 'No',
      '2' => 'Yes',
      '602' => "Client doesn't know",
      '603' => 'Client prefers not to answer',
      '1830' => 'Data not collected',
      '1732' => 'Not eligible',
      '1733' => 'Did not apply',
      '1734' => 'Pending decision',
    }.freeze
    def cde_value(value)
      CDE_VALUE_MAP.fetch(value) if value
    end

    def owner_class
      Hmis::Hud::Enrollment
    end
  end
end
