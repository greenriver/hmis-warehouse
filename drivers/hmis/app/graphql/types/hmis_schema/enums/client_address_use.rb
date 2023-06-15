###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ClientAddressUse < Types::BaseEnum
    description 'Allowed values for ClientAddress.use'
    graphql_name 'ClientAddressUse'

    Hmis::Hud::CustomClientAddress.use_values.each do |val|
      value val, val.to_s.humanize
    end
  end
end
