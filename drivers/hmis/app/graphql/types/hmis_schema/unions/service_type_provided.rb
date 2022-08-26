###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Unions::ServiceTypeProvided < Types::BaseUnion
    description 'HUD Service TypeProvided field'
    graphql_name 'ServiceTypeProvided'

    possible_types HmisSchema::Enums::PATHService, HmisSchema::Enums::RHYService

    def resolve_type
      HmisSchema::Enums::PATHService
    end
  end
end
