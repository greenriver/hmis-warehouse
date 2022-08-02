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

    def gender_map
      Hmis::Hud::Client.gender_enum_map
    end

    def race_map
      Hmis::Hud::Client.race_enum_map
    end

    def multi_field_attrs(input_field, enum_map, none_field)
      result = {}
      return result unless input_field.present?

      null_value = input_field.find { |val| enum_map.null_member?(value: val) }

      if null_value.nil?
        input_field.each do |value|
          member = enum_map.lookup(value: value)
          result[member[:key]] = 1
        end
      else
        enum_map.base_members.each do |member|
          result[member[:key]] = 99
        end
        result[none_field] = null_value unless none_field.nil?
      end

      result
    end

    def gender_attrs
      multi_field_attrs(gender, gender_map, 'GenderNone')
    end

    def race_attrs
      multi_field_attrs(race, race_map, 'RaceNone')
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

      result
    end
  end
end
