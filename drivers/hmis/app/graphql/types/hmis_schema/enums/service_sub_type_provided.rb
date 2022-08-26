###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ServiceSubTypeProvided < Types::BaseEnum
    description 'HUD Service TypeProvided:SubTypeProvided aggregate (V2.A, V2.B, V2.C)'
    graphql_name 'ServiceSubTypeProvided'

    [
      ['144:3', HmisSchema::Enums::SSVFSubType3],
      ['144:4', HmisSchema::Enums::SSVFSubType4],
      ['144:5', HmisSchema::Enums::SSVFSubType5],
    ].each do |record_type, enum|
      rt_key, rt_value = HmisSchema::Enums::ServiceTypeProvided.enum_member_for_value(record_type)
      enum.values.each do |enum_key, enum_value|
        value [rt_key, enum_key].join('__'), [rt_value.description, enum_value.description].join(' – '), value: [rt_value.value, enum_value.value].join(':')
      end
    end
  end
end
