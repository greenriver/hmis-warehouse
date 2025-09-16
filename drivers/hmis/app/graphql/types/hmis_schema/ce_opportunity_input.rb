###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeOpportunityInput < Types::BaseInputObject
    argument :template_identifier, String, required: true
    argument :name, String, required: true
    # TBD
    # expiration
    # argument :requirements, String, required: false
    # argument :unit_type, ID, required: true
    # argument :service_type, ID, required: true
  end
end
