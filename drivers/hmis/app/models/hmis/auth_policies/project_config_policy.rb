# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AuthPolicies::ProjectConfigPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_update?
      in_data_source? && can_manage?
    end

    def can_destroy?
      in_data_source? && can_manage?
    end

    protected

    def in_data_source?
      resource.data_source_id == user.hmis_data_source_id
    end

    def can_manage?
      global_permissions.include?(:can_configure_data_collection)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::ProjectConfig)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_create? = can_manage?

    def can_view? = can_manage?

    protected

    def can_manage?
      global_permissions.include?(:can_configure_data_collection)
    end

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::ProjectConfig)
  end
end
