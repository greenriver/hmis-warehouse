###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Root-level access object resolved from Query.access.
#
# These fields reflect the user's global (data-source-scoped) permissions — whether they can do
# something somewhere in the current HMIS data source, such as create clients or manage forms.
# Permissions about a specific record (e.g. can I view this client's name?) belong on that
# record's access object (ClientAccess, ProjectAccess, etc.), not here.
module Types
  class HmisSchema::RootQueryAccess < Types::BaseAccess
    skip_activity_log
    graphql_name 'QueryAccess'

    field :id, ID, null: false

    def id
      current_user.id
    end

    bool_field(:can_manage_forms) { form_definition_policy.can_manage_forms? }
    bool_field(:can_administrate_config) { form_definition_policy.can_administrate_config? }

    # can_configure_data_collection is deprecated, and usages should be replaced by more-specific permission checks that delegate to policies.
    # These policies all still check can_configure_data_collection internally, but using the policies in the frontend is aligned with our pattern and allows for future flexibility
    bool_field(:can_configure_data_collection, deprecation_reason: 'Use policy permission specific to the need, such as canManageFormRules or canManageServices') { current_user.can_configure_data_collection? || false }
    bool_field(:can_manage_form_rules) { form_definition_policy.can_manage_form_rules? }
    bool_field(:can_manage_services) { service_type_policy.can_manage? }
    bool_field(:can_manage_project_configs) { project_config_policy.can_manage? }

    bool_field(:can_impersonate_users) { hmis_user_policy.can_impersonate_users? }
    bool_field(:can_audit_users) { hmis_user_policy.can_audit_users? }

    # can_manage_denied_referrals is a legacy permission for our custom referrals solution that predated CE.
    # It's not worth updating to use the new policy pattern, since we plan to sunset it.
    bool_field(:can_manage_denied_referrals) { current_user.can_manage_denied_referrals? || false }

    bool_field(:can_merge_clients) { hmis_client_policy.can_merge_clients? }
    bool_field(:can_edit_users_in_warehouse) { warehouse_user.can_edit_users? }

    bool_field(:can_manage_ce_default_contacts) { ce_referral_policy.can_manage_ce_default_contacts? }
    bool_field(:can_manage_ce_match_rules) { ce_match_rule_policy.can_manage? }
    bool_field(:can_index_opportunities) { ce_opportunity_policy.can_index_opportunities? }
    bool_field(:can_index_eligible_clients) { ce_opportunity_policy.can_index_eligible_clients? }
    bool_field(:can_bulk_void_ce_clients) { ce_opportunity_policy.can_bulk_void_ce_clients? }

    bool_field(:can_view_clients) { hmis_client_policy.can_view? }
    bool_field(:can_edit_clients, deprecation_reason: 'Use canCreateClients when checking for creation permission. Use client access object when checking for ability to edit a specific client.') { hmis_client_policy.can_create? }
    bool_field(:can_create_clients) { hmis_client_policy.can_create? }
    bool_field(:can_view_dob) { hmis_client_policy.can_view_dob? }
    bool_field(:can_view_client_alerts) { hmis_client_policy.can_view_client_alerts? }

    bool_field(:can_edit_organization, deprecation_reason: 'Use canCreateOrganizations when checking for creation permission. Use organization access object when checking for ability to edit a specific organization.') { hmis_organization_policy.can_create? }
    bool_field(:can_create_organizations) { hmis_organization_policy.can_create? }
    bool_field(:can_edit_project_details, deprecation_reason: 'Use canCreateProjects on the organization access object') { current_user.can_edit_project_details? || false }

    bool_field(:can_index_referrals) { ce_referral_policy.can_index? }

    private

    def form_definition_policy
      @form_definition_policy ||= policy_for(Hmis::Form::Definition, policy_type: :form_definition)
    end

    def ce_referral_policy
      @ce_referral_policy ||= policy_for(Hmis::Ce::Referral, policy_type: :ce_referral)
    end

    def hmis_client_policy
      @hmis_client_policy ||= policy_for(Hmis::Hud::Client, policy_type: :hmis_client)
    end

    def hmis_user_policy
      @hmis_user_policy ||= policy_for(Hmis::User, policy_type: :hmis_user)
    end

    def ce_opportunity_policy
      @ce_opportunity_policy ||= policy_for(Hmis::Ce::Opportunity, policy_type: :ce_opportunity)
    end

    def service_type_policy
      @service_type_policy ||= policy_for(Hmis::Hud::CustomServiceType, policy_type: :service_type)
    end

    def project_config_policy
      @project_config_policy ||= policy_for(Hmis::ProjectConfig, policy_type: :project_config)
    end

    def hmis_organization_policy
      @hmis_organization_policy ||= policy_for(Hmis::Hud::Organization, policy_type: :hmis_organization)
    end

    def ce_match_rule_policy
      @ce_match_rule_policy ||= policy_for(Hmis::Ce::Match::Rule, policy_type: :ce_match_rule)
    end

    def warehouse_user
      @warehouse_user ||= User.find(current_user.id)
    end
  end
end
