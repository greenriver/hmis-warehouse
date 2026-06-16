###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::SortDirection < Types::BaseEnum
    description 'Sorting Direction'
    graphql_name 'SortDirection'

    value 'ASC', 'Ascending', value: :asc
    value 'DESC', 'Descending', value: :desc
  end
end
