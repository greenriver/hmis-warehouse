###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ClientContactPointSystem < Types::BaseEnum
    description 'Allowed values for ClientContactPoint.system'
    graphql_name 'ClientContactPointSystem'

    Hmis::Hud::CustomClientContactPoint.system_values.each do |val|
      value val
    end
  end
end
