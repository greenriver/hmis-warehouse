###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::ReasonNoServices < Types::BaseEnum
    description 'R2.A'
    graphql_name 'ReasonNoServices'
    value OUT_OF_AGE_RANGE, '(1) Out of age range', value: 1
    value WARD_OF_THE_STATE, '(2) Ward of the state', value: 2
    value WARD_OF_THE_CRIMINAL_JUSTICE_SYSTEM, '(3) Ward of the criminal justice system', value: 3
    value OTHER, '(4) Other', value: 4
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
