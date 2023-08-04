###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::RelatedRecordType < Types::BaseEnum
    description 'Related record type for a group of questions in an assessment'
    graphql_name 'RelatedRecordType'

    value 'CLIENT', 'Client'
    value 'ENROLLMENT', 'Enrollment'
    value 'ENROLLMENT_COC', 'EnrollmentCoc'
    value 'INCOME_BENEFIT', 'IncomeBenefit'
    value 'DISABILITY_GROUP', 'DisabilityGroup'
    value 'HEALTH_AND_DV', 'HealthAndDv'
    value 'EXIT', 'Exit'
    value 'CURRENT_LIVING_SITUATION', 'CurrentLivingSituation'
    value 'YOUTH_EDUCATION_STATUS', 'YouthEducationStatus'
    value 'EMPLOYMENT_EDUCATION', 'EmploymentEducation'
  end
end
