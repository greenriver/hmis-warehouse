###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::PrioritizationStatus < Types::BaseEnum
    description '4.19.7'
    graphql_name 'PrioritizationStatus'
    value PLACED_ON_PRIORITIZATION_LIST, '(1) Placed on prioritization list', value: 1
    value NOT_PLACED_ON_PRIORITIZATION_LIST, '(2) Not placed on prioritization list', value: 2
  end
end
