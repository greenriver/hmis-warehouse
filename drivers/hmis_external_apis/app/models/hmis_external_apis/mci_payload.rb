###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class MciPayload
    def self.from_client(client)
      # FIXME: I need more documentation on what's required and how to
      # correctly leave things out. Various attempts at partial payloads result
      # in error messages that aren't helpful like:
      #   "Object reference not set to an instance of an object."
      #   "Length cannot be less than zero. (Parameter 'length')"
      #
      #   What do we send when we don't have a date? null doesn't seem to work nor the empty string.
      #   Perhaps it's: "0001-01-01T00:00:00"
      payload = {
        # 'userID' => 'string',
        'otherNames' => {
          'firstName' => client.preferred_name,
          'lastName' => client.preferred_name,
        },
        # 'isHomeless' => true,
        'ssnAlias' => client.ssn, # Should be last 4 digits of ssn, if we only have that
        'ethnicityCode' => 7, # Gig to do mapping
        'ethnicityDesc' => 'WCDesc', # I would guess not needed, but can pull from ::HudLists.ethnicity_map
        # 'tribeCode' => 414,
        # 'tribeDesc' => 'WCDesc',
        # 'maritalStatus' => 8,
        # 'housingStatus' => 15,
        'genderCode' => 1, # Gig to do mapping
        # 'residencyCode' => 3,
        'firstName' => client.first_name,
        'middleName' => client.middle_name,
        'lastName' => client.last_name,
        'suffix' => client.name_suffix,
        'ssn' => client.ssn, # Should be complete SSN, if we have it
        'birthDate' => client.dob.to_s(:db),
        'raceCodes' => '2-,', # Gig to do mapping
        # 'deathDate' => '2019-05-09T11:23:31.129Z',
      }

      # if false # FIXME: get external id if we have it
      #   # FIXME: pseudo-code:
      #   # payload["mciId"] => client.external_ids.mci_id
      # end

      payload
    end

    # FIXME: what do we need?
    def self.build_client(parsed_body)
      Hmis::Hud::Client.new(
        first_name: parsed_body['firstName'],
        last_name: parsed_body['lastName'],
        mci_id: parsed_body['mciId'],
      )
    end
  end
end
