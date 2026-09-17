###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  # Roles that can appear in the Forms admin tool, for filtering that table. Excludes the roles that
  # Hmis::Form::Definition.configurable_by drops, which could never match a listed form.
  class Forms::Enums::ConfigurableFormRole < Types::BaseEnum
    graphql_name 'ConfigurableFormRole'

    with_enum_map Hmis::Form::Definition.configurable_form_role_enum_map, prefix_description_with_key: false
  end
end
