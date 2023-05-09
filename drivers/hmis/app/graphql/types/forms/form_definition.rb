###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormDefinition < Types::BaseObject
    description 'FormDefinition'
    field :id, ID, null: false
    field :version, Int, null: false
    field :role, Types::Forms::Enums::FormRole, null: false
    field :status, String, null: false
    field :identifier, String, null: false
    field :definition, Forms::FormDefinitionJson, null: false

    def definition
      JSON.parse(object.definition)
    end
  end
end
