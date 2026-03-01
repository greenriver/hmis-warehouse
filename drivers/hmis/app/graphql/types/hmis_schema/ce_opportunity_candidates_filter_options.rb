###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeOpportunityCandidatesFilterOptions < Types::BaseInputObject
    graphql_name 'CeOpportunityCandidatesFilterOptions'

    argument :exclude_declined_clients, Boolean, required: false, default_value: false
    argument :search_term, String, required: false
  end
end
