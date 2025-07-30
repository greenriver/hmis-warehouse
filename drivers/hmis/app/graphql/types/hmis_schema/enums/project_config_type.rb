###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ProjectConfigType < Types::BaseEnum
    graphql_name 'ProjectConfigType'

    value 'AUTO_EXIT', description: 'Auto Exit'
    value 'AUTO_ENTER', description: 'Auto Enter'
    value 'STAFF_ASSIGNMENT', description: 'Staff Assignment'
    value 'COORDINATED_ENTRY', description: 'Coordinated Entry Referrals'
    value 'SENDS_DIRECT_CE_REFERRALS', description: 'Outgoing Referrals'
  end
end
