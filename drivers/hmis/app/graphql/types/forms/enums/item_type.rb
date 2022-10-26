###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::ItemType < Types::BaseEnum
    graphql_name 'ItemType'

    # unused types are commented out for now

    value 'GROUP'
    value 'DISPLAY'
    value 'BOOLEAN'
    # value 'DECIMAL'
    value 'INTEGER'
    value 'DATE'
    # value 'DATETIME'
    value 'STRING'
    value 'TEXT'
    value 'CHOICE'
    value 'OPEN_CHOICE'
  end
end
