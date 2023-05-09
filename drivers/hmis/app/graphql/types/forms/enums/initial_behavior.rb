###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::InitialBehavior < Types::BaseEnum
    graphql_name 'InitialBehavior'
    value 'OVERWRITE', description: 'When loading the form, always overwrite the existing value with specified initial value.'
    value 'IF_EMPTY', description: 'When loading the form, only set the specified initial value if there is no existing value.'
  end
end
