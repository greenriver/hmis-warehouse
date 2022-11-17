###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::RelatedRecordType < Types::BaseEnum
    description 'Related record type for a group of questions in an assessment'
    graphql_name 'RelatedRecordType'

    value 'ENROLLMENT'
    value 'INCOME_BENEFITS'
    value 'DISABILITIES'
    value 'HEALTH_AND_DV'
    value 'EXIT'
    value 'CURRENT_LIVING_SITUATION'
    value 'YOUTH_EDUCATION_STATUS'
    value 'EMPLOYMENT_EDUCATION'
  end
end
