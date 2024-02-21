###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::Enums::ItemType < Types::BaseEnum
    graphql_name 'ItemType'

    # unused types are commented out for now

    value 'GROUP'
    value 'DISPLAY'
    value 'BOOLEAN'
    value 'CURRENCY'
    # value 'DECIMAL'
    value 'INTEGER'
    value 'DATE'
    # value 'DATETIME'
    value 'TIME_OF_DAY'
    value 'STRING'
    value 'TEXT'
    value 'CHOICE'
    value 'OPEN_CHOICE'
    value 'IMAGE'
    value 'FILE'
    value 'OBJECT'
  end
end
