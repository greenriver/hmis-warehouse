###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::FormRole < Types::BaseEnum
    description 'Form Role'
    graphql_name 'FormRole'

    with_enum_map Hmis::Form::Definition.form_role_enum_map

    def self.as_data_collection_stage(role)
      Hmis::Form::Definition::FORM_DATA_COLLECTION_STAGES[role.to_sym] || 99
    end
  end
end
