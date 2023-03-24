module Types
  class HmisSchema::Transformers::ClientInputTransformer < HmisSchema::Transformers::BaseTransformer
    def gender_map
      Hmis::Hud::Client.gender_enum_map
    end

    def race_map
      Hmis::Hud::Client.race_enum_map
    end

    def self.multi_field_attrs(input_field, enum_map, not_collected_key, none_field)
      result = {}
      return result if input_field.nil?

      null_value = input_field.find { |val| enum_map.null_member?(value: val) }
      null_value = enum_map.lookup(key: not_collected_key)[:value] if input_field.empty?

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
      self.class.multi_field_attrs(gender, gender_map, 'Data not collected', :GenderNone)
    end

    def race_attrs
      self.class.multi_field_attrs(race, race_map, :data_not_collected, :RaceNone)
    end

    def to_params
      result = {}

      result['FirstName'] = first_name
      result['LastName'] = last_name
      result['MiddleName'] = middle_name
      result['NameSuffix'] = name_suffix
      result['preferred_name'] = preferred_name
      result['NameDataQuality'] = name_data_quality
      result['DOB'] = dob
      result['DOBDataQuality'] = dob_data_quality
      result['SSN'] = ssn&.gsub(/[^\dXx]/, '')
      result['SSNDataQuality'] = ssn_data_quality
      result['Ethnicity'] = ethnicity
      result['VeteranStatus'] = veteran_status
      result['pronouns'] = pronouns&.join('|')
      result['image_blob_id'] = image_blob_id if image_blob_id.present?

      result = result.merge(race_attrs)
      result = result.merge(gender_attrs)
      # TODO: YearEnteredService, YearSeparated, WorldWarII, KoreanWar, VietnamWar, DesertStorm, AfghanistanOEF, IraqOIF, IraqOND, OtherTheater, MilitaryBranch, DischargeStatus

      result
    end
  end
end
