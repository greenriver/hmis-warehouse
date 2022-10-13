###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::FormDefinition < Types::BaseObject
    description 'HUD FormDefinition'
    field :id, ID, null: false
    field :version, Int, null: false
    field :role, String, null: false
    field :status, String, null: false
    field :identifier, String, null: false
    field :definition, JsonObject, null: false
  end
end
