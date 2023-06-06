###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::AssessmentRole < Types::BaseEnum
    graphql_name 'AssessmentRole'

    with_enum_map Hmis::Form::Definition.assessment_type_enum_map
  end
end
