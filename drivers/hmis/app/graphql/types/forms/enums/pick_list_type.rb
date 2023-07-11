###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    value 'ORGANIZATION', 'All Organizations that the User can see'
    value 'GEOCODE'
    value 'STATE'
    value 'PRIOR_LIVING_SITUATION'
    value 'CURRENT_LIVING_SITUATION'
    value 'DESTINATION'
    value 'ALL_UNIT_TYPES', 'All unit types.'
    value 'UNIT_TYPES', 'Unit types. If project is specified, limited to unit types in the project.'
    value 'AVAILABLE_UNIT_TYPES', 'Unit types that have unoccupied units in the specified project'
    value 'UNITS', 'Units in the specified project'
    value 'AVAILABLE_UNITS', 'Unoccupied units in the specified project'
    value 'ALL_SERVICE_TYPES'
    value 'ALL_SERVICE_CATEGORIES'
    value 'AVAILABLE_SERVICE_TYPES'
    value 'SUB_TYPE_PROVIDED_3'
    value 'SUB_TYPE_PROVIDED_4'
    value 'SUB_TYPE_PROVIDED_5'
    value 'REFERRAL_OUTCOME'
    value 'AVAILABLE_FILE_TYPES'
    value 'CLIENT_ENROLLMENTS', 'All Enrollments, including WIP and exited, for the client.'
    value 'PROJECT_HOH_ENROLLMENTS', 'Project HOH Enrollments, including WIP and exited, for the client.'
    value 'REFERRAL_RESULT_TYPES', 'Referral Result '
    value 'ASSIGNED_REFERRAL_POSTING_STATUSES', 'Referral Posting Status'
    value 'DENIED_PENDING_REFERRAL_POSTING_STATUSES', 'Referral Posting Status'
  end
end
