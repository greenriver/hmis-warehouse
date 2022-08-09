module Types
  class HmisSchema::Transformers::ClientInputTransformer < HmisSchema::Transformers::BaseTransformer
    def gender_map
      Hmis::Hud::Client.gender_enum_map
    end

    def race_map
      Hmis::Hud::Client.race_enum_map
    end

    def multi_field_attrs(input_field, enum_map, none_field)
      result = {}
      return result if input_field.nil?

      null_value = input_field.find { |val| enum_map.null_member?(value: val) }
      null_value = enum_map.lookup(key: :not_collected)[:value] if input_field.empty?

      if null_value.nil?
        enum_map.base_members.map { |item| item[:value] }.each do |value|
          member = enum_map.lookup(value: value)
          result[member[:key]] = input_field.include?(value) ? 1 : 0
        end
        result[none_field] = nil
      else
        enum_map.base_members.each do |member|
          result[member[:key]] = 99
        end
        result[none_field] = null_value unless none_field.nil?
      end

      result
    end

    def gender_attrs
      multi_field_attrs(gender, gender_map, :GenderNone)
    end

    def race_attrs
      multi_field_attrs(race, race_map, :RaceNone)
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
      result['SSN'] = ssn&.gsub(/\D/, '')
      result['SSNDataQuality'] = ssn_quality
      result['Ethnicity'] = ethnicity
      result['VeteranStatus'] = veteran_status

      result = result.merge(race_attrs)
      result = result.merge(gender_attrs)
      # TODO: YearEnteredService, YearSeparated, WorldWarII, KoreanWar, VietnamWar, DesertStorm, AfghanistanOEF, IraqOIF, IraqOND, OtherTheater, MilitaryBranch, DischargeStatus

      result
    end
  end
end
