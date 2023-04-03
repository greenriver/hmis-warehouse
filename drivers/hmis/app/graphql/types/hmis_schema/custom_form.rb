###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomForm < Types::BaseObject
    description 'CustomForm'
    field :id, ID, null: false
    field :definition, Forms::FormDefinition, null: false
    field :assessment, HmisSchema::Assessment, null: false
    field :values, JsonObject, null: true

    def assessment
      load_ar_association(object, :assessment)
    end

    def definition
      load_ar_association(object, :definition)
    end
  end
end
