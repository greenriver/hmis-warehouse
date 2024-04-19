###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Forms::Enums::PickListType < Types::BaseEnum
    graphql_name 'PickListType'

    value 'COC'
    value 'PROJECT', 'All Projects that the User can see'
    value 'ENROLLABLE_PROJECTS', 'Projects that the User can enroll Clients in'
    value 'RESIDENTIAL_PROJECTS', 'Residential Projects'
    value 'ORGANIZATION', 'All Organizations that the User can see'
    value 'ASSESSMENT_TYPES'
    value 'GEOCODE'
    value 'STATE'
    value 'PRIOR_LIVING_SITUATION'
    value 'CURRENT_LIVING_SITUATION'
    value 'DESTINATION'
    value 'ALL_UNIT_TYPES', 'All unit types.'
    value 'POSSIBLE_UNIT_TYPES_FOR_PROJECT', 'Unit types that are eligible to be added to project'
    value 'AVAILABLE_UNIT_TYPES', 'Unit types that have unoccupied units in the specified project'
    value 'AVAILABLE_UNITS_FOR_ENROLLMENT', 'Units available for the given household at the given project'
    value 'ALL_SERVICE_TYPES'
    value 'ALL_SERVICE_CATEGORIES'
    value 'AVAILABLE_SERVICE_TYPES'
    value 'AVAILABLE_BULK_SERVICE_TYPES'
    value 'SUB_TYPE_PROVIDED_3'
    value 'SUB_TYPE_PROVIDED_4'
    value 'SUB_TYPE_PROVIDED_5'
    value 'REFERRAL_OUTCOME'
    value 'AVAILABLE_FILE_TYPES'
    value 'ENROLLMENTS_FOR_CLIENT', 'Enrollments for the client, including WIP and Exited.'
    value 'OPEN_HOH_ENROLLMENTS_FOR_PROJECT', 'Open HoH enrollments at the project.'
    value 'EXTERNAL_FORM_TYPES_FOR_PROJECT', 'External form types for the project.'
    value 'CE_EVENTS', 'Grouped HUD CE Event types'
    value 'ENROLLMENT_AUDIT_EVENT_RECORD_TYPES'
    value 'CLIENT_AUDIT_EVENT_RECORD_TYPES'
    value 'USERS', 'User Accounts'
  end
end
