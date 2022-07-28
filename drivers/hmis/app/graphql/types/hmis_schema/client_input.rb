module Types
  class HmisSchema::ClientInput < BaseInputObject
    description 'HMIS Client input'

    argument :first_name, String, required: false
    argument :middle_name, String, required: false
    argument :last_name, String, required: false
    argument :preferred_name, String, required: false
    argument :name_quality, Types::HmisSchema::Enums::NameDataQuality, required: false
    # TODO: Needs more discussion
    # argument :pronouns, [String], required: false
    argument :dob, String, required: false
    argument :dob_quality, Types::HmisSchema::Enums::DOBDataQuality, required: false
    argument :ssn, String, required: false
    argument :ssn_quality, Types::HmisSchema::Enums::SSNDataQuality, required: false
    argument :gender, [Types::HmisSchema::Enums::Gender], required: false
    argument :race, [Types::HmisSchema::Enums::Race], required: false
    argument :ethnicity, Types::HmisSchema::Enums::Ethnicity, required: false
    argument :veteran_status, Types::HmisSchema::Enums::VeteranStatus, required: false

    def gender_attrs
      result = {}
      return result unless gender.present?

      gender_none_values = [
        Types::HmisSchema::Enums::Gender.values['GENDER_UNKNOWN'].value,
        Types::HmisSchema::Enums::Gender.values['GENDER_REFUSED'].value,
        Types::HmisSchema::Enums::Gender.values['GENDER_NOT_COLLECTED'].value,
      ]

      if gender.any? { |val| gender_none_values.include?(val) }
        result['Female'] = 99
        result['Male'] = 99
        result['NoSingleGender'] = 99
        result['Transgender'] = 99
        result['Questioning'] = 99
        result['GenderNone'] = gender_none_values.find { |val| gender.include?(val) }
      else
        result['Female'] = 1 if gender.include?(Types::HmisSchema::Enums::Gender.values['GENDER_FEMALE'].value)
        result['Male'] = 1 if gender.include?(Types::HmisSchema::Enums::Gender.values['GENDER_MALE'].value)
        result['NoSingleGender'] = 1 if gender.include?(Types::HmisSchema::Enums::Gender.values['GENDER_NO_SINGLE_GENDER'].value)
        result['Transgender'] = 1 if gender.include?(Types::HmisSchema::Enums::Gender.values['GENDER_TRANSGENDER'].value)
        result['Questioning'] = 1 if gender.include?(Types::HmisSchema::Enums::Gender.values['GENDER_QUESTIONING'].value)
      end

      result
    end

    def race_attrs
      result = {}
      return result unless race.present?

      race_none_values = [
        Types::HmisSchema::Enums::Race.values['RACE_UNKNOWN'].value,
        Types::HmisSchema::Enums::Race.values['RACE_REFUSED'].value,
        Types::HmisSchema::Enums::Race.values['RACE_NOT_COLLECTED'].value,
      ]

      if race.any? { |val| race_none_values.include?(val) }
        result['AmIndAKNative'] = 99
        result['Asian'] = 99
        result['BlackAfAmerican'] = 99
        result['NativeHIPacific'] = 99
        result['White'] = 99
        result['RaceNone'] = race_none_values.find { |val| race.include?(val) }
      else
        result['AmIndAKNative'] = 1 if race.include?(Types::HmisSchema::Enums::Race.values['RACE_AM_IND_AK_NATIVE'].value)
        result['Asian'] = 1 if race.include?(Types::HmisSchema::Enums::Race.values['RACE_ASIAN'].value)
        result['BlackAfAmerican'] = 1 if race.include?(Types::HmisSchema::Enums::Race.values['RACE_BLACK_AF_AMERICAN'].value)
        result['NativeHIPacific'] = 1 if race.include?(Types::HmisSchema::Enums::Race.values['RACE_NATIVE_HI_PACIFIC'].value)
        result['White'] = 1 if race.include?(Types::HmisSchema::Enums::Race.values['RACE_WHITE'].value)
      end

      result
    end

    def to_params
      result = {}

      result['FirstName'] = first_name
      result['LastName'] = last_name
      result['MiddleName'] = middle_name
      result['preferred_name'] = preferred_name
      result['NameDataQuality'] = name_quality
      result['DOB'] = dob
      result['DOBDataQuality'] = dob_quality
      result['SSN'] = ssn
      result['SSNDataQuality'] = ssn_quality
      result['Ethnicity'] = ethnicity
      result['VeteranStatus'] = veteran_status

      result = result.merge(race_attrs)
      result = result.merge(gender_attrs)

      puts '~~~~~~~~~~~~~', result, '~~~~~~~~~~~~~'

      result
    end
  end
end
