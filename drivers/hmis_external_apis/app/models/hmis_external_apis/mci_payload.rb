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
        'userID' => 'string',
        'otherNames' => {
          'firstName' => 'JosON',
          'middleName' => 'WCON',
          'lastName' => 'ButlerON',
          'suffix' => 'ENGON',
          'dateVerified' => '2019-05-09T11:23:31.127Z',
          'dateUpdated' => '2019-05-09T11:23:31.127Z',
        },
        'isHomeless' => true,
        'isUSCitizen' => 3,
        'ssnAlias' => '999888123',
        'ethnicityCode' => 7,
        'ethnicityDesc' => 'WCDesc',
        'tribeCode' => 414,
        'tribeDesc' => 'WCDesc',
        'maritalStatus' => 8,
        'housingStatus' => 15,
        'genderCode' => 1,
        'address' => [
          {
            'addressLine1' => '123 Main Street',
            'addressLine2' => 'Over there',
            'addressTypeCode' => 1,
            'aptNumber' => '100',
            'city' => 'Coolcity',
            'cityCouncilDistrictCode' => 5,
            'countyCode' => 7,
            'countyCouncilDistrictCode' => 8,
            'isCurrentResidence' => true,
            'isVerified' => true,
            'municipalityCode' => 19,
            'schoolDistrictCode' => '12',
            'stateCode' => 'AZ',
            'zipCode' => '11111',
            'zipCodeExt' => 'NDZC',
            'countryCode' => 97,
            'startDate' => '2019-05-09T11:23:31.128Z',
          },
          {
            'addressLine1' => '423 Broadway Mailing',
            'addressLine2' => 'unit 3',
            'addressTypeCode' => 2,
            'aptNumber' => '102',
            'city' => 'Cool',
            'cityCouncilDistrictCode' => 2,
            'countyCode' => 2,
            'countyCouncilDistrictCode' => 2,
            'isCurrentResidence' => true,
            'isVerified' => true,
            'municipalityCode' => 2,
            'schoolDistrictCode' => '2',
            'stateCode' => 'AZ',
            'zipCode' => '66212',
            'zipCodeExt' => '1234',
            'countryCode' => 37,
            'startDate' => '2019-05-09T11:23:31.128Z',
          },
          {
            'addressLine1' => '515 High Street OTHERU',
            'addressLine2' => 'Near Opera House OTHERU',
            'addressTypeCode' => 3,
            'aptNumber' => '1093',
            'city' => 'Cool',
            'cityCouncilDistrictCode' => 3,
            'countyCode' => 3,
            'countyCouncilDistrictCode' => 3,
            'isCurrentResidence' => true,
            'isVerified' => true,
            'municipalityCode' => 3,
            'schoolDistrictCode' => '3',
            'stateCode' => 'NY',
            'zipCode' => 'NYZ',
            'zipCodeExt' => 'NYZE',
            'countryCode' => 90,
            'startDate' => '2019-05-09T11:23:31.128Z',
          },
        ],
        'contact' => {
          'homePhone' => '5655652377',
          'faxNumber' => '5655652504',
          'email' => 'contacttest1@gmail.com',
          'workPhone' => '565565',
          'workPhoneExt' => '33333',
          'cellPhone' => '7045652777',
        },
        'residencyCode' => 3,
        'firstName' => client.first_name,
        'middleName' => client.middle_name,
        'lastName' => client.last_name,
        'suffix' => client.name_suffix,
        'ssn' => client.ssn,
        'birthDate' => client.dob.to_s(:db),
        'raceCodes' => '2-,',
        'deathDate' => '2019-05-09T11:23:31.129Z',
      }

      # if true # FIXME: birth name exists
      #   payload['birthName'] = {
      #     'firstName' => client.first_name,
      #     'middleName' => client.middle_name,
      #     'lastName' => client.last_name,
      #     'suffix' => client.name_suffix,
      #     'dateVerified' => '2019-05-09T11:23:31.127Z',
      #     'dateUpdated' => '2019-05-09T11:23:31.127Z',
      #   }
      # end

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
