###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class MciPayload
    def self.from_client(client, mci_id: nil)
      raise 'First name is required' unless client.first_name.present?
      raise 'Last name is required' unless client.last_name.present?
      raise 'DOB is required' unless client.dob.present?

      {
        'userID' => client.user&.user_email&.slice(0, 20),
        'firstName' => client.first_name,
        'middleName' => client.middle_name,
        'lastName' => client.last_name,
        'suffix' => client.name_suffix,
        # API only accepts full SSNs
        'ssn' => client.ssn&.match?(/^\d{9}$/) ? client.ssn : nil,
        'birthDate' => client.dob.to_s(:db) + 'T00:00:00',
        'raceCodes' => MciMapping.mci_races(client),
        'ethnicityCode' => MciMapping.mci_ethnicity(client),
        'genderCode' => MciMapping.mci_gender(client),
        'mciId' => mci_id,
        # TODO: confirm before setting these
        # 'sourceSystemId' => HmisExternalApis::AcHmis::DataWarehouseApi.new.src_sys_key
        # 'sourceSystemClientId' => client.personal_id
      }.compact_blank
    end

    def self.build_client(parsed_body)
      # Note: ignoring ethnicityCode because it's not present on clearance result
      # Note: ignoring genderCode because it's not present on clearance result
      gender_fields = MciMapping.hud_gender_from_text(parsed_body['genderText'])
      race_fields = MciMapping.hud_races(parsed_body['raceCodes'])

      attributes = {
        first_name: parsed_body['firstName'],
        middle_name: parsed_body['middleName'],
        last_name: parsed_body['lastName'],
        name_suffix: parsed_body['suffix'],
        ssn: parsed_body['ssn'] || parsed_body['ssnAlias'],
        dob: parsed_body['birthDate'],
        **gender_fields,
        **race_fields,
      }.compact_blank

      ::Hmis::Hud::Client.new(attributes)
    end
  end
end
