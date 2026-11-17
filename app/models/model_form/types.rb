###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ModelForm
  # Attribute types that cast the way Virtus (via the coercible gem) did: a value that can't be
  # converted is returned unchanged rather than becoming nil, 0 or true.
  module Types
    def self.lookup(type)
      case type
      when nil then nil
      when ::Array then Array.new(member: lookup(type.first))
      else
        BY_CLASS[type]&.new
      end
    end

    class String < ActiveModel::Type::Value
      private def cast_value(value)
        case value
        when ActiveSupport::TimeWithZone then value
        when ::BigDecimal then value.to_s('F')
        when ::Numeric, true, false, ::Symbol, ::Date, ::Time then value.to_s
        else value.respond_to?(:to_str) ? value.to_str : value
        end
      end
    end

    class Integer < ActiveModel::Type::Value
      INTEGER = /\A[-+]?(?:[0-9]\d*)\z/
      NUMERIC = /\A([-+]?(?:[0-9]\d*)(?:\.\d+)?(?:[eE][-+]?\d+)?|(?:\.\d+)(?:[eE][-+]?\d+)?)\z/

      private def cast_value(value)
        case value
        when ActiveSupport::TimeWithZone then value
        when ::String then cast_string(value)
        when ::Numeric, ::Time then value.to_i
        else value.respond_to?(:to_int) ? value.to_int : value
        end
      end

      private def cast_string(value)
        return value.to_i if INTEGER.match?(value)

        match = NUMERIC.match(value)
        match ? match[1].to_f.to_i : value
      end
    end

    class Date < ActiveModel::Type::Value
      private def cast_value(value)
        case value
        when ActiveSupport::TimeWithZone then value
        when ::String then parse(value)
        when ::Date, ::Time then value.to_date
        when ::Hash then from_parts(value)
        else value
        end
      end

      private def parse(value)
        ::Date.parse(value)
      rescue ::ArgumentError
        value
      end

      private def from_parts(value)
        now = ::Time.now
        parts = { year: now.year, month: now.month, day: now.day }.map do |key, fallback|
          Types::Integer.new.cast(value.fetch(key, fallback))
        end
        ::Date.new(*parts)
      end
    end

    class Boolean < ActiveModel::Type::Value
      STRINGS = ['1', 'on', 't', 'true', 'y', 'yes'].index_with(true).
        merge(['0', 'off', 'f', 'false', 'n', 'no'].index_with(false)).freeze
      INTEGERS = { 0 => false, 1 => true }.freeze

      private def cast_value(value)
        case value
        when ::String then STRINGS.fetch(value.downcase, value)
        when ::Integer then INTEGERS.fetch(value, value)
        else value
        end
      end
    end

    class Symbol < ActiveModel::Type::Value
      private def cast_value(value)
        value.is_a?(::String) ? value.to_sym : value
      end
    end

    class Array < ActiveModel::Type::Value
      def initialize(member: nil)
        @member = member
        super()
      end

      def cast(value)
        values = ::Kernel.Array(value)
        @member ? values.map { |entry| @member.cast(entry) } : values.dup
      end
    end

    BY_CLASS = {
      ::String => String,
      ::Integer => Integer,
      ::Date => Date,
      Boolean => Boolean,
      ::Symbol => Symbol,
      ::Array => Array,
    }.freeze
  end
end
