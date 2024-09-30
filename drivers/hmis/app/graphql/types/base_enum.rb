###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseEnum < GraphQL::Schema::Enum
    INVALID_VALUE = -999999

    def self.build(name, &block)
      Class.new(self) do
        graphql_name(name)
        instance_eval(&block)
      end
    end

    def self.generate_enum(name, &block)
      @generated_enums = {} unless @generated_enums.present?
      @generated_enums[name] ||= build(name, &block)
    end

    def self.to_enum_key(value)
      key = value.to_s.underscore.upcase.
        gsub(/\s*\(.{18,}\)$/, ''). # remove long parenthesized text
        gsub(/\W+/, '_'). # replace spaces with underscores
        gsub(/_+/, '_').gsub(/_$/, '').gsub(/^_/, '') # clean up
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
        member_values[:key] = 'DATA_NOT_COLLECTED' if member_values[:value]&.to_s == '99'

        value to_enum_key(member_values[:key]), member_values[:desc], value: member_values[:value], deprecation_reason: member_values[:deprecation_reason]
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

    def self.value_for(key)
      raise "Unrecognized key '#{key}' for enum #{name}" unless values.key?(key)

      values[key].value
    end

    # Given a token that could be either a key OR a value OR a string representation of an int value,
    # return the int value that we should save to the database. Examples: 'YES' => 1, '1' => 1,  1 => 1
    def self.flexible_value_for(token)
      if values.key?(token)
        values[token].value
      elsif value?(token)
        token
      elsif value?(token.to_i)
        token.to_i
      else
        raise "Unrecognized key '#{token}' for enum #{name}"
      end
    end

    def self.value?(maybe_val)
      # values is the hash of string => GraphQL::Schema::EnumValue
      # values.values is the values list of that hash, aka a list of GraphQL::Schema::EnumValue
      # values.values.map(&:value) is the list of value attributes on those GraphQL::Schema::EnumValues
      # whew!
      @internal_values ||= values.values.map(&:value)
      @internal_values.include?(maybe_val)
    end

    def self.key_for(value)
      member = enum_member_for_value(value)
      raise "Unrecognized value '#{value}' for enum #{name}" unless member.present?

      member.first
    end

    def self.data_not_collected_value
      member = enum_member_for_value(99) || enum_member_for_value('99')
      member&.last&.value
    end
  end
end
