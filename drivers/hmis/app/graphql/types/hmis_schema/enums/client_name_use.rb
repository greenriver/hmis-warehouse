###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ClientNameUse < Types::BaseEnum
    description 'Allowed values for ClientName.use'
    graphql_name 'ClientNameUse'

    Hmis::Hud::CustomClientName.use_values.each do |val|
      value val
    end
  end
end
