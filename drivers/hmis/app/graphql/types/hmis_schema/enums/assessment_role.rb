###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::AssessmentRole < Types::BaseEnum
    description 'Assessment Role'
    graphql_name 'AssessmentRole'

    value 'INTAKE'
    value 'UPDATE'
    value 'ANNUAL'
    value 'EXIT'
    value 'CE'
    value 'POST_EXIT'
    value 'CUSTOM', 'Custom HMIS Assessment'
    value 'RESOURCE', 'Form for creating or editing resources directly'
  end
end
