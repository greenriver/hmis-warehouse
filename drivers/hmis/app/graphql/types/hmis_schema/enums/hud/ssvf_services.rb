###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types
  class HmisSchema::Enums::Hud::SSVFServices < Types::BaseEnum
    description 'V2.2'
    graphql_name 'SSVFServices'
    value 'OUTREACH_SERVICES', '(1) Outreach services', value: 1
    value 'CASE_MANAGEMENT_SERVICES', '(2) Case management services', value: 2
    value 'ASSISTANCE_OBTAINING_VA_BENEFITS', '(3) Assistance obtaining VA benefits', value: 3
    value 'ASSISTANCE_OBTAINING_COORDINATING_OTHER_PUBLIC_BENEFITS', '(4) Assistance obtaining/coordinating other public benefits', value: 4
    value 'DIRECT_PROVISION_OF_OTHER_PUBLIC_BENEFITS', '(5) Direct provision of other public benefits', value: 5
    value 'OTHER_NON_TFA_SUPPORTIVE_SERVICE_APPROVED_BY_VA', '(6) Other (non-TFA) supportive service approved by VA', value: 6
  end
end
