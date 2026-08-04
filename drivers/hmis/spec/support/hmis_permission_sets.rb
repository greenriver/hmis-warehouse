###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Permission sets that only take effect when granted together.
#
# Enrollment visibility is resolved with `with_access(..., mode: :all)`, which matches a single
# Role granting every listed permission, so specs must pass these sets to one
# create_access_control call rather than splitting them across access controls.
module HmisPermissionSets
  ENROLLMENT_VISIBILITY = [:can_view_enrollment_details, :can_view_project, :can_view_clients].freeze
  LIMITED_ENROLLMENT_VISIBILITY = [:can_view_limited_enrollment_details, :can_view_clients].freeze
end
