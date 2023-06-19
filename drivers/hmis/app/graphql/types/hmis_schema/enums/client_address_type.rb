###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ClientAddressType < Types::BaseEnum
    description 'Allowed values for ClientAddress.type'
    graphql_name 'ClientAddressType'

    Hmis::Hud::CustomClientAddress.type_values.each do |val|
      value val, val.to_s.humanize
    end
  end
end
