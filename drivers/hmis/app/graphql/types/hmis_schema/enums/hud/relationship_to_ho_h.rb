###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::RelationshipToHoH < Types::BaseEnum
    description '3.15.1'
    graphql_name 'RelationshipToHoH'
    value 'SELF_HEAD_OF_HOUSEHOLD', '(1) Self (head of household)', value: 1
    value 'CHILD', '(2) Child', value: 2
    value 'SPOUSE_OR_PARTNER', '(3) Spouse or partner', value: 3
    value 'OTHER_RELATIVE', '(4) Other relative', value: 4
    value 'UNRELATED_HOUSEHOLD_MEMBER', '(5) Unrelated household member', value: 5
    value 'DATA_NOT_COLLECTED', '(99) Data not collected', value: 99
  end
end
