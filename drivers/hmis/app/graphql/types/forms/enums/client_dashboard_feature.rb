###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Forms::Enums::ClientDashboardFeature < Types::BaseEnum
    graphql_name 'ClientDashboardFeature'

    value 'CASE_NOTE'
    value 'FILE'
  end
end
