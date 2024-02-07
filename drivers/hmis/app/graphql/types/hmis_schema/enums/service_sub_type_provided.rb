###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ServiceSubTypeProvided < Types::BaseEnum
    description 'HUD Service TypeProvided:SubTypeProvided aggregate (V2.A, V2.B, V2.C)'
    graphql_name 'ServiceSubTypeProvided'

    [
      ['144:3', HmisSchema::Enums::Hud::SSVFSubType3],
      ['144:4', HmisSchema::Enums::Hud::SSVFSubType4],
      ['144:5', HmisSchema::Enums::Hud::SSVFSubType5],
    ].each do |record_type, enum|
      rt_key, rt_value = HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value(record_type)
      enum.values.each do |enum_key, enum_value|
        next if enum_value.value == Types::BaseEnum::INVALID_VALUE

        value [rt_key, enum_key].join('__'), enum_value.description, value: [rt_value.value, enum_value.value].join(':')
      end
    end
    invalid_value
  end
end
