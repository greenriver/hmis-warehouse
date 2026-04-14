# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AuthPolicies::ProjectConfigPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Global < Hmis::AuthPolicies::BasePolicy
    # Whether the user can manage project configs in the current HMIS data source.
    def can_manage?
      global_permissions.include?(:can_configure_data_collection)
    end

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::ProjectConfig)
  end
end
