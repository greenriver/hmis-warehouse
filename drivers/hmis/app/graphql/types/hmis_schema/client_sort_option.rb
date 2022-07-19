###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientSortOption < Types::BaseEnum
    description 'HUD Client Sorting Options'
    graphql_name 'ClientSortOption'

    value 'LAST_NAME', 'Client Last Name', value: 'LastName'

    # TODO: Add more sorting options if needed
  end
end
