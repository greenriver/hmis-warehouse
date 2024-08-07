###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ServiceTypeProvided < Types::BaseEnum
    description 'HUD Service RecordType:TypeProvided aggregate (P1.2, R14.2, W1.2, V2.2, W2.2, V3.3, P2.2, 4.14, V8.2, C2.2)'
    graphql_name 'ServiceTypeProvided'

    [
      [141, HmisSchema::Enums::Hud::PATHServices], # P1.2
      [142, HmisSchema::Enums::Hud::RHYServices], # R14.2
      [143, HmisSchema::Enums::Hud::HOPWAServices], # W1.2
      [144, HmisSchema::Enums::Hud::SSVFServices], # V2.2
      [151, HmisSchema::Enums::Hud::HOPWAFinancialAssistance], # W2.2
      [152, HmisSchema::Enums::Hud::SSVFFinancialAssistance], # V3.3
      [161, HmisSchema::Enums::Hud::PATHReferral], # P2.2
      [200, HmisSchema::Enums::Hud::BedNight], # 4.14
      [210, HmisSchema::Enums::Hud::VoucherTracking], # V8.2
      [300, HmisSchema::Enums::Hud::MovingOnAssistance], # C2.2
    ].each do |record_type, enum|
      rt_key, rt_value = HmisSchema::Enums::Hud::RecordType.enum_member_for_value(record_type)
      enum.values.each do |enum_key, enum_value|
        next if enum_value.value == Types::BaseEnum::INVALID_VALUE

        value [rt_key, enum_key].join('__'), enum_value.description, value: [rt_value.value, enum_value.value].join(':')
      end
    end
    invalid_value
  end
end
