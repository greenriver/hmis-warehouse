###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectsWithCeDefaultContactsFilterOptions < Types::BaseInputObject
    graphql_name 'ProjectsWithCeDefaultContactsFilterOptions'

    argument :organization, [ID], required: false
    argument :project, [ID], required: false, description: 'Filter by project ID(s)'
    argument :user, [ID], required: false, description: 'Filter by user assigned as default contact'

    def to_params
      to_h.compact
    end
  end
end
