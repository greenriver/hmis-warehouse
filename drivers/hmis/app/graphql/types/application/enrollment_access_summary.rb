###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class Application::EnrollmentAccessSummary < Types::BaseObject
    # maps to Hmis::EnrollmentAccessSummary
    graphql_name 'EnrollmentAccessSummary'
    field :id, ID, null: false
    field :last_accessed_at, GraphQL::Types::ISO8601DateTime, null: false
    field :enrollment, HmisSchema::Enrollment, null: true

    def enrollment
      load_ar_association(object, :enrollment)
    end
  end
end
