###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisUserPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Global < Hmis::AuthPolicies::BasePolicy
    def can_impersonate_users?
      global_permissions.include?(:can_impersonate_users)
    end

    def can_audit_users?
      global_permissions.include?(:can_audit_users)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::User)
  end
end
