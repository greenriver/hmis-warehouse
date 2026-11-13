###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Permission sets that only take effect when granted together, because of the requirements declared
# in Hmis::Role.permissions_with_descriptions. They may be granted by one role or several, as long as
# every permission applies to the same project.
module HmisPermissionSets
  ENROLLMENT_VISIBILITY = [:can_view_enrollment_details, :can_view_project, :can_view_clients].freeze
  LIMITED_ENROLLMENT_VISIBILITY = [:can_view_limited_enrollment_details, :can_view_clients].freeze
  ENROLLMENT_EDITING = [:can_edit_enrollments, *ENROLLMENT_VISIBILITY].freeze
end
