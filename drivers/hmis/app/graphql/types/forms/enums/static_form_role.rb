###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::StaticFormRole < Types::BaseEnum
    graphql_name 'StaticFormRole'
    description 'Form Roles that are used for non-configurable forms. These types of forms are submitted using custom mutations.'

    with_enum_map Hmis::Form::Definition.static_form_role_enum_map, prefix_description_with_key: false
  end
end
