###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisSupplemental
  Field = Struct.new(:key, :label, :type, :multi_valued, :data_set, keyword_init: true) do
    DELIMITER = '|'.freeze
    TYPES = [
      STRING_TYPE = 'string'.freeze,
      ID_TYPE = 'id'.freeze,
      INT_TYPE = 'int'.freeze,
      FLOAT_TYPE = 'float'.freeze,
      BOOLEAN_TYPE = 'boolean'.freeze,
      DATE_TYPE = 'date'.freeze,
    ].freeze
    CLIENT_OWNER = 'client'.freeze
    CLIENT_ID_FIELD = 'personal_id'.freeze
    ENROLLMENT_OWNER = 'owner'.freeze
    ENROLLMENT_ID_FIELD = 'enrollment_id'.freeze

    def format_value(field_value)
      value = field_value&.data
      if multi_valued
        return [] unless value.present?

        return value.map { |i| format_single_value(i) }.join(', ')
      end
      format_single_value(value)
    end

    # @return [String, nil]
    def format_single_value(value)
      return if value.nil?

      case type
      when STRING_TYPE, ID_TYPE
        value.to_s
      when INT_TYPE
        value.to_i.to_s
      when FLOAT_TYPE
        # 2 decimals seems like reasonable default. Could be configurable
        format('%.2f', value.to_f)
      when BOOLEAN_TYPE
        value ? 'true' : 'false'
      when DATE_TYPE
        parse_date(value)&.to_fs
      else
        raise "unknown type: #{type}"
      end
    end

    def row_owner_key(row)
      owner_id = row_owner_id(row)
      return nil unless owner_id

      "#{owner_type}/#{row_owner_id(row)}"
    end

    def row_owner_id(row)
      case owner_type
      when CLIENT_OWNER
        row[CLIENT_ID_FIELD].presence
      when ENROLLMENT_OWNER
        row[ENROLLMENT_ID_FIELD].presence
      else
        raise "#{owner_type} not supported"
      end
    end

    def owner_type
      data_set.owner_type
    end

    def row_value_data(row)
      value = row[key.to_s].presence
      return if value.nil?

      if multi_valued
        value.to_s.split(DELIMITER).compact_blank.map { |part| cast_value(part) }.presence
      else
        cast_value(value)
      end
    end

    def cast_value(value)
      case type
      when STRING_TYPE, ID_TYPE
        value.to_s
      when INT_TYPE
        value.to_i
      when FLOAT_TYPE
        value.to_f
      when BOOLEAN_TYPE
        cast_to_boolean(value)
      when DATE_TYPE
        parse_date(value)&.to_fs(:db)
      else
        raise "#{type} not supported"
      end
    end

    def cast_to_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def parse_date(string)
      Date.strptime(string, '%Y-%m-%d')
    rescue ArgumentError
      nil
    end
  end
end
