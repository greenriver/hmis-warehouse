###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::EvictionHistory < Types::BaseEnum
    description 'V7.G'
    graphql_name 'EvictionHistory'
    value NO_PRIOR_RENTAL_EVICTIONS, '(0) No prior rental evictions', value: 0
    value NUM_1_PRIOR_RENTAL_EVICTION, '(1) 1 prior rental eviction', value: 1
    value NUM_2_OR_MORE_PRIOR_RENTAL_EVICTIONS, '(2) 2 or more prior rental evictions', value: 2
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
