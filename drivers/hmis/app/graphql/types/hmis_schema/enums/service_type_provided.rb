###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ServiceTypeProvided < Types::BaseEnum
    description 'HUD Service RecordType:TypeProvided aggregate'
    graphql_name 'ServiceTypeProvided'

    [
      [141, HmisSchema::Enums::PATHService],
      [142, HmisSchema::Enums::RHYService],
    ].each do |record_type, enum|
      rt_key, rt_value = HmisSchema::Enums::RecordType.enum_member_for_value(record_type)
      enum.values.each do |enum_key, enum_value|
        value [rt_key, enum_key].join('_'), [rt_value.description, enum_value.description].join(' – '), value: [rt_value.value, enum_value.value].join(':')
      end
    end
  end
end
