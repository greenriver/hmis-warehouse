###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::CustomDataElementType < Types::BaseEnum
    description 'Allowed values for CustomDataElementDefinition.type'
    graphql_name 'CustomDataElementType'

    Hmis::Hud::CustomDataElementDefinition::FIELD_TYPES.each do |val|
      value val
    end
  end
end
