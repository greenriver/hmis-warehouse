###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'

# Resolves access group IDs into final permission sets for a user.
module Hmis::AuthPolicies::ContextLoaders
  class HmisPermissionLoader
    include Memery
    EMPTY_SET = Set.new.freeze

    def initialize(user)
      @user = user
    end

    # Callers pass access group ids in whatever order their query produced. Sort them before memoizing to
    # keep one cache entry per set rather than one per ordering.
    def for_access_group_ids(access_group_ids)
      return EMPTY_SET if access_group_ids.blank?

      for_sorted_access_group_ids(access_group_ids.to_a.sort)
    end

    protected

    memoize def for_sorted_access_group_ids(access_group_ids)
      raw_permissions = Hmis::Role.joins(:access_controls).
        merge(@user.access_controls.where(access_group_id: access_group_ids)).
        flat_map(&:granted_permissions).to_set

      apply_permission_requirements(raw_permissions).freeze
    end

    # Drops permissions whose requirements aren't also granted. Requirements are transitive:
    # required_permissions_for returns the full chain, so can_edit_enrollments needs
    # can_view_enrollment_details plus everything that permission requires.
    def apply_permission_requirements(permissions)
      permissions.delete_if do |permission|
        !Hmis::Role.required_permissions_for(permission).all? { |required| permissions.include?(required) }
      end
    end
  end
end
