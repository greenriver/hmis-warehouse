###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::DisabledDisplay < Types::BaseEnum
    graphql_name 'DisabledDisplay'
    value 'HIDDEN'
    value 'PROTECTED'
  end
end
