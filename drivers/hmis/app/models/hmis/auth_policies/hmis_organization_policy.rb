###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::HmisOrganizationPolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_edit? # Whether the user can edit this organization
      organization_permissions.include?(:can_edit_organization)
    end

    def can_create_project? # Whether the user can create projects in this organization
      organization_permissions.include?(:can_edit_project_details)
    end

    protected

    memoize def organization_permissions
      context.organization_permissions(resource)
    end

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Hud::Organization)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_create? # Whether the user can create organizations in the data source
      global_permissions.include?(:can_edit_organization)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Hud::Organization)
  end
end
