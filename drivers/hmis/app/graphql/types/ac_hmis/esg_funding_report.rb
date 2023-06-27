###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class AcHmis::EsgFundingReport < Types::BaseObject
    description 'AC ESG Funding Report'
    field :esg_funding_services, [Types::AcHmis::EsgFundingService], null: false

    # object is a scope on Hmis::Hud::CustomService

    def esg_funding_services
      object&.preload(:project, :client, :organization) || []
    end
  end
end
