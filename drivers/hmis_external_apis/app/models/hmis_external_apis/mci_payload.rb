###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class MciPayload
    def self.from_client(client)
      raise 'First name is missing' unless client.first_name.present?
      raise 'Last name is missing' unless client.last_name.present?
      raise 'DOB is missing' unless client.dob.present?

      # FIXME: I need more documentation on what's required and how to
      # correctly leave things out. Various attempts at partial payloads result
      # in error messages that aren't helpful like:
      #   "Object reference not set to an instance of an object."
      #   "Length cannot be less than zero. (Parameter 'length')"
      payload = {
        # 'userID' => 'string',
        # 'otherNames' => {
        #   'firstName' => client.preferred_name,
        #   'lastName' => client.preferred_name,
        # },
        # 'isHomeless' => true,
        'ethnicityCode' => 7, # TODO: Gig to do mapping
        'ethnicityDesc' => 'WCDesc', # TODO: Gig to do mapping, ::HudLists.ethnicity_map
        # 'tribeCode' => 414,
        # 'tribeDesc' => 'WCDesc',
        # 'maritalStatus' => 8,
        # 'housingStatus' => 15,
        'genderCode' => 1, # TODO: Gig to do mapping
        # 'residencyCode' => 3,
        'firstName' => client.first_name,
        'middleName' => client.middle_name,
        'lastName' => client.last_name,
        'suffix' => client.name_suffix,
        'ssn' => client.ssn,
        # 'ssnAlias' => client.ssn,
        'birthDate' => client.dob.to_s(:db),
        'raceCodes' => '2-,', # TODO: Gig to do mapping
        # 'deathDate' => '2019-05-09T11:23:31.129Z',
        'mciId' => client.external_ids_by_slug('mci').first,
      }

      payload
    end

    def self.build_client(parsed_body)
      cleaned_ssn = clean_ssn(parsed_body['ssn'] || parsed_body['ssnAlias'])
      Hmis::Hud::Client.new(
        first_name: parsed_body['firstName'],
        middle_name: parsed_body['middleName'],
        last_name: parsed_body['lastName'],
        name_suffix: parsed_body['suffix'],
        ssn: cleaned_ssn,
        dob: parsed_body['birthDate'], # FIXME does it need parsing?
        # TODO(gig): parsed_body['raceCodes'],
        # TODO(gig): parsed_body['ethnicityCode'],
        # TODO(gig): parsed_body['genderCode'],
      )

      # TODO: create related ExternalId record with value parsed_body['mciId']
    end

    # TODO: ensure SSN is HUD-compliant (exactly 9 chars, missing values replaced with X or x)
    def self.clean_ssn(ssn)
      # Strip any dashes or non-numeric non-[X|x] chars
      # If 9 chars and all numeric or x|X, return
      # If <9 chars, prefix with X's to make it be 9 chars
      # If >9 chars, trim to 9?
      ssn
    end
  end
end
