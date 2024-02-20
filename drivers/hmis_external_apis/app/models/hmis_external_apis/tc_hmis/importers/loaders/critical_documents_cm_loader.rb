###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CriticalDocumentsCmLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'cdcm_state_in_possession', label: 'Which of the follow do you have in your possession?', field_type: 'string', repeats: true },
      { element_id: 2974, key: 'cdcm_in_possession_other', label: 'Specify Other', field_type: 'string', repeats: false },
      { key: 'cdcm_state_id_expired', label: 'Is your State ID Card expired?', field_type: 'boolean', repeats: false },
      { key: 'cdcm_id_card_state', label: 'ID Card State', field_type: 'string', repeats: false },
      { key: 'cdcm_state_id_audit_number', label: 'State ID AUDIT Number', field_type: 'string', repeats: false },
      { key: 'cdcm_license_expired', label: 'Is your Driver License expired?', field_type: 'boolean', repeats: false },
      { key: 'cdcm_license_state', label: 'Driver License State', field_type: 'string', repeats: false },
      { key: 'cdcm_license_audit_number', label: 'Drivers License AUDIT Number', field_type: 'string', repeats: false },
      { key: 'cdcm_need_assistance_obtaining', label: 'Which of the follow do you need assistance obtaining?', field_type: 'string', repeats: true },
      { element_id: 2975, key: 'cdcm_need_assistance_other', label: 'Specify Other', field_type: 'string', repeats: false },
      { key: 'cdcm_birth_certificate_state', label: 'Birth Certificate State', field_type: 'string', repeats: false },
      { key: 'cdcm_obtainment_plan_1', label: '1.', field_type: 'string', repeats: false },
      { key: 'cdcm_obtainment_plan_2', label: '2.', field_type: 'string', repeats: false },
      { key: 'cdcm_obtainment_plan_3', label: '3.', field_type: 'string', repeats: false },
      { key: 'cdcm_obtainment_plan_4', label: '4.', field_type: 'string', repeats: false },
      { key: 'cdcm_obtainment_plan_5', label: '5.', field_type: 'string', repeats: false },
      { key: 'cdcm_note', label: 'Case Notes', field_type: 'string', repeats: false },
      { key: 'cdcm_signature_cd_specialist', label: 'Critical Document Specialist', field_type: 'string', repeats: false },
      { key: 'cdcm_signature_client', label: 'Client Signature', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'CDCM.xlsx'
    end

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "cdcm-eto-#{response_id}"
    end

    def cde_values(row, config)
      cded_key = config.fetch(:key)
      values = super(row, config)
      values = values.map { |value| value ? 'Signed in ETO' : nil } if cded_key =~ /signature/i
      values
    end
  end
end
