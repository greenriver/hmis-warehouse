###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::BoundType < Types::BaseEnum
    graphql_name 'BoundType'

    value 'MIN'
    value 'MAX'
    # value 'MIN_VALUE'
    # value 'MAX_VALUE'
    # value 'MIN_LENGTH'
    # value 'MAX_LENGTH'
  end
end
