###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CeParticipationServices < Types::BaseEnum
    graphql_name 'CeParticipationServices'
    # Used for multi-select on 2.09 Coordinated Entry Participation Status to indicate CE services provided by the project.
    # See HMIS Data Dictionary for more information

    value 'PREVENTION_ASSESSMENT', 'Homelessness Prevention Assessment, Screening, and/or Referral', value: 1
    value 'CRISIS_ASSESSMENT', 'Shelter Assessment, Screening, and/or Referral', value: 2
    value 'HOUSING_ASSESSMENT', 'Housing Assessment, Screening, and/or Referral', value: 3
    value 'DIRECT_SERVICES', 'Direct Services (search and/or placement support)', value: 4
  end
end
