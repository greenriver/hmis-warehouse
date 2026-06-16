###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::AuthPolicies::CeMatchRulePolicy < Hmis::AuthPolicies::ResourcePolicy
  class Instance < Hmis::AuthPolicies::BasePolicy
    def can_create? = can_manage?
    def can_update? = can_manage?
    def can_delete? = can_manage?

    protected

    def can_manage?
      return false unless Hmis::Ce.configuration.enabled?
      return false unless in_data_source?

      global_permissions.include?(:can_administrate_coordinated_entry)
    end

    def in_data_source?
      return false unless rule.owner

      case rule.owner
      when GrdaWarehouse::DataSource
        rule.owner_id == user.hmis_data_source_id
      when Hmis::UnitGroup
        rule.owner.project.data_source_id == user.hmis_data_source_id
      else
        rule.owner.data_source_id == user.hmis_data_source_id
      end
    end

    def rule = resource

    def validate_resource!(arg) = ensure_arg_type!(arg, Hmis::Ce::Match::Rule)
  end

  class Global < Hmis::AuthPolicies::BasePolicy
    def can_create?
      return false unless Hmis::Ce.configuration.enabled?

      global_permissions.include?(:can_administrate_coordinated_entry)
    end

    protected

    def validate_resource!(arg) = ensure_arg_class!(arg, Hmis::Ce::Match::Rule)
  end
end
