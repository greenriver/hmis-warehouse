###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseEnum < GraphQL::Schema::Enum
    def self.to_enum_key(value)
      value.to_s.underscore.upcase.gsub(/\W+/, '_').gsub(/_+/, '_')
    end

    def self.with_enum_map(enum_map, prefix: '')
      enum_map.members.each do |member|
        member_values = member.dup
        member_values[:key] = "#{prefix}#{member[:key]}"
        member_values[:desc] = "(#{member_values[:value]}) #{member_values[:desc]}"
        member_values = yield member if block_given?
        value to_enum_key(member_values[:key]), member_values[:desc], value: member_values[:value]
      end
    end

    def self.enum_member_for_value(value)
      values.find { |_, v| v.value == value }
    end
  end
end
