###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Admin::FormDefinitionInput < Types::BaseInputObject
    argument :role, Types::Forms::Enums::FormRole, required: false
    argument :identifier, String, required: false
    argument :title, String, required: false
    argument :definition, String, required: false

    def to_attributes
      to_h.except(:definition)
    end
  end
end
