###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseEnum < GraphQL::Schema::Enum
    INVALID_VALUE = -999999

    def self.to_enum_key(value)
      key = value.to_s.underscore.upcase.gsub(/\W+/, '_').gsub(/_+/, '_').gsub(/_$/, '').gsub(/^_/, '')
      key = "NUM_#{key}" if key.match(/^[0-9]/)
      key
    end

    def self.with_enum_map(enum_map, prefix: '', prefix_description_with_key: true)
      enum_map.members.each do |member|
        member_values = member.dup
        member_values[:key] = "#{prefix}#{member[:key]}"
        member_values[:desc] = prefix_description_with_key ? "(#{member_values[:value]}) #{member_values[:desc]}" : member_values[:desc]
        member_values = yield member if block_given?

        # Ensure we are using DATA_NOT_COLLECTED key for 99s
        member_values[:key] = 'DATA_NOT_COLLECTED' if member_values[:value] == 99

        value to_enum_key(member_values[:key]), member_values[:desc], value: member_values[:value]
      end
    end

    def self.enum_member_for_value(value)
      values.find { |_, v| v.value == value }
    end

    def self.coerce_result(value, ctx)
      super(value, ctx)
    rescue self::UnresolvedValueError => e
      # If unable to coerce results and this enum supports INVALID, then return that
      invalid = values.each_value.find { |val| val.value == INVALID_VALUE }
      return invalid.graphql_name if invalid.present?

      raise e
    end

    def self.invalid_value
      value 'INVALID', 'Invalid Value', value: INVALID_VALUE
    end

    def self.hud_enum(hash)
      values = hash.map do |key, desc|
        {
          key: desc,
          value: key,
          desc: desc,
        }
      end
      with_enum_map(Hmis::FieldMap.new(values))
      invalid_value # Always define invalid value on HUD enums
    end

    def self.value_for(key)
      raise "Unrecognized key '#{key}' for enum #{name}" unless values.key?(key)

      values[key].value
    end

    def self.key_for(value)
      member = enum_member_for_value(value)
      raise "Unrecognized value '#{value}' for enum #{name}" unless member.present?

      member.first
    end

    def self.data_not_collected_value
      enum_member_for_value(99)&.last&.value
    end
  end
end
