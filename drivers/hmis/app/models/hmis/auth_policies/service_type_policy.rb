###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::ServiceTypePolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_destroy?
      # HUD-linked types are not deletable through the custom service type editor
      return false if resource.hud_service?

      in_data_source? && can_manage?
    end

    protected

    def in_data_source?
      resource.data_source_id == user.hmis_data_source_id
    end

    def can_manage?
      global_permissions.include?(:can_configure_data_collection)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::CustomServiceType)
  end
end
