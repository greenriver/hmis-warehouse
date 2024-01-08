###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::ClientDashboardFeature < Types::BaseEnum
    graphql_name 'ClientDashboardFeature'

    value 'CASE_NOTE'
    value 'FILE'
  end
end
