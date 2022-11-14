###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::IncarceratedParentStatus < Types::BaseEnum
    description '4.33.A'
    graphql_name 'IncarceratedParentStatus'
    value ONE_PARENT_LEGAL_GUARDIAN_IS_INCARCERATED, '(1) One parent / legal guardian is incarcerated', value: 1
    value BOTH_PARENTS_LEGAL_GUARDIANS_ARE_INCARCERATED, '(2) Both parents / legal guardians are incarcerated', value: 2
    value THE_ONLY_PARENT_LEGAL_GUARDIAN_IS_INCARCERATED, '(3) The only parent / legal guardian is incarcerated', value: 3
    value DATA_NOT_COLLECTED, '(99) Data not collected', value: 99
  end
end
