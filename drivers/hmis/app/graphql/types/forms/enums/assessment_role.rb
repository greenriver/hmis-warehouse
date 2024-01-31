###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::AssessmentRole < Types::BaseEnum
    graphql_name 'AssessmentRole'
    description 'Form Roles that are used for assessments. These types of forms are submitted using SubmitAssessment.'

    with_enum_map Hmis::Form::Definition.assessment_type_enum_map, prefix_description_with_key: false
  end
end
