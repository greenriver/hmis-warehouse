###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ServiceTypeProvided < Types::BaseEnum
    description 'HUD Service RecordType:TypeProvided aggregate (P1.2, R14.2, W1.2, V2.2, W2.3, V3.3, P2.2, 4.14, V8.1, C2.2)'
    graphql_name 'ServiceTypeProvided'

    [
      [141, HmisSchema::Enums::PATHService],
      [142, HmisSchema::Enums::RHYService],
      [143, HmisSchema::Enums::HOPWAService],
      [144, HmisSchema::Enums::SSVFService],
      [151, HmisSchema::Enums::HOPWAFinancialAssistance],
      [152, HmisSchema::Enums::SSVFFinancialAssistance],
      [161, HmisSchema::Enums::PATHReferral],
      [200, HmisSchema::Enums::BedNight],
      [210, HmisSchema::Enums::VoucherTracking],
      [300, HmisSchema::Enums::MovingOnAssistance],
    ].each do |record_type, enum|
      rt_key, rt_value = HmisSchema::Enums::RecordType.enum_member_for_value(record_type)
      enum.values.each do |enum_key, enum_value|
        value [rt_key, enum_key].join('__'), [rt_value.description, enum_value.description].join(' – '), value: [rt_value.value, enum_value.value].join(':')
      end
    end
  end
end
