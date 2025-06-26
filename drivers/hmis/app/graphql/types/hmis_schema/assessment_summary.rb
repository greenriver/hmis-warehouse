###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentSummary < Types::BaseObject
    # object is a Hmis::Hud::CustomAssessment
    # This type resolves limited metadata about an assessment for "extended access" scenarios (e.g. CE referral use case.)
    # There is no object-level authorization because the current user may not have access to view the full assessment.

    field :id, ID, null: false
    field :assessment_name, String, null: false
    field :assessment_date, GraphQL::Types::ISO8601Date, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: true

    def assessment_name
      load_ar_association(object, :definition).title
    end
  end
end
