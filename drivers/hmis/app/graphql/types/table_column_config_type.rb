###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class TableColumnConfigType < Types::BaseEnum
    graphql_name 'TableColumnConfigType'

    Hmis::TableConfiguration::COLUMN_TYPES.each do |type|
      value type.upcase, value: type
    end
  end
end
