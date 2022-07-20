###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectSortOption < Types::BaseEnum
    description 'HUD Project Sorting Options'
    graphql_name 'ProjectSortOption'

    # define as a method?
    value 'ORGANIZATION_AND_NAME', 'Organizaton Name and Project Name', value: 'organization_and_name'
  end
end
