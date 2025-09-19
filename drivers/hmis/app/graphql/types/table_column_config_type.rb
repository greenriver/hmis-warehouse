###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
