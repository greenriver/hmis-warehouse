###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class MciPayload
    def self.from_client(client, mci_id: nil)
      raise(Error, 'First name is required') unless client.first_name.present?
      raise(Error, 'Last name is required') unless client.last_name.present?
      raise(Error, 'DOB is required') unless client.dob.present?

      {
        # TODO: pass Okta User ID
        # 'userID' => 'string',
        'firstName' => client.first_name,
        'middleName' => client.middle_name,
        'lastName' => client.last_name,
        'suffix' => client.name_suffix,
        'ssn' => client.ssn,
        # 'ssnAlias' => client.ssn,
        'birthDate' => client.dob.to_s(:db) + 'T00:00:00',
        'raceCodes' => MciMapping.mci_races(client),
        'ethnicityCode' => MciMapping.mci_ethnicity(client),
        'genderCode' => MciMapping.mci_gender(client),
        'mciId' => mci_id,
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
