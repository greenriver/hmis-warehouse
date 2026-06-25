###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::FormRole < Types::BaseEnum
    graphql_name 'FormRole'

    with_enum_map Hmis::Form::Definition.form_role_enum_map, prefix_description_with_key: false
  end
end
