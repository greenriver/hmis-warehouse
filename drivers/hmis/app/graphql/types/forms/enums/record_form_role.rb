###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::RecordFormRole < Types::BaseEnum
    graphql_name 'RecordFormRole'
    description 'Form Roles that are used for record-editing. These types of forms are submitted using SubmitForm.'

    with_enum_map Hmis::Form::Definition.record_form_role_enum_map, prefix_description_with_key: false
  end
end
