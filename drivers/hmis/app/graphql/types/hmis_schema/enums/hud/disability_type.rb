###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::DisabilityType < Types::BaseEnum
    description '1.3'
    graphql_name 'DisabilityType'
    value 'PHYSICAL_DISABILITY', '(5) Physical disability', value: 5
    value 'DEVELOPMENTAL_DISABILITY', '(6) Developmental disability', value: 6
    value 'CHRONIC_HEALTH_CONDITION', '(7) Chronic health condition', value: 7
    value 'HIV_AIDS', '(8) HIV/AIDS', value: 8
    value 'MENTAL_HEALTH_DISORDER', '(9) Mental health disorder', value: 9
    value 'SUBSTANCE_USE_DISORDER', '(10) Substance use disorder', value: 10
  end
end
