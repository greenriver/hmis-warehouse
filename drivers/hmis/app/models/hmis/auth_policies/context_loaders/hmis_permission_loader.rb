###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

    memoize def for_access_group_ids(access_group_ids)
      return EMPTY_SET if access_group_ids.blank?

      raw_permissions = Hmis::Role.joins(:access_controls).
        merge(@user.access_controls.where(access_group_id: access_group_ids)).
        flat_map(&:granted_permissions).to_set

      apply_permission_requirements(raw_permissions).freeze
    end

    protected

    def apply_permission_requirements(permissions)
      # support cycle detection for requirement chains
      visited = Set.new

      permissions.delete_if do |permission|
        !has_requirements_met?(permission, permissions, visited)
      end
    end

    # Recursively checks that a permission and all its transitive requirements are satisfied
    def has_requirements_met?(permission, permissions, visited)
      raise 'cycle detected' if visited.include?(permission) # This shouldn't occur

      required = role_config[permission][:requirements]

      return true if required.blank? # No requirements, keep it

      # check that all requirements are satisfied
      visited.add(permission)
      result = required.all? do |req|
        permissions.include?(req) && has_requirements_met?(req, permissions, visited)
      end
      visited.delete(permission)

      result
    end

    # note, the config is not memoized on Role (as of this time) so memoize here
    memoize def role_config
      Hmis::Role.permissions_with_descriptions.freeze
    end
  end
end
