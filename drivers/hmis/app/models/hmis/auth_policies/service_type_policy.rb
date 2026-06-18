###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::ServiceTypePolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_delete? = can_manage?

    def can_edit? = can_manage?

    protected

    def in_data_source?
      resource.data_source_id == user.hmis_data_source_id
    end

    def can_manage?
      # HUD-linked types are not manageable through the custom service type editor
      return false if resource.hud_service?

      in_data_source? && global_permissions.include?(:can_configure_data_collection)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::CustomServiceType)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_manage?
      global_permissions.include?(:can_configure_data_collection)
    end

    def can_create? = can_manage?

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::CustomServiceType)
  end
end
