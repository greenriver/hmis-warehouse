###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::FormDefinitionForJsonResult < Types::BaseObject
    skip_activity_log
    field :definition, Types::Forms::FormDefinitionJson, null: true
    field :errors, [String], null: false
  end
end
