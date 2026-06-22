###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Organization < Types::BaseObject
    include Types::HmisSchema::HasProjects
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::Organization.hmis_configuration(version: '2024')
    end

    available_filter_options do
      arg :search_term, String
      arg :ce_waitlists_enabled, Boolean
    end

    field :id, ID, null: false
    field :hud_id, ID, null: false, method: :organization_id
    field :organization_name, String, null: false
    field :effective_ce_match_rule_count, Integer, null: false, description: 'Number of rules that apply to this organization, including inherited rules.'
    field :local_ce_match_rule_count, Integer, null: false, description: 'Number of rules owned directly by this organization.'
    field :effective_ce_match_rule_groups, [HmisSchema::CeMatchRuleGroup], null: false
    projects_field :projects, filter_args: { omit: [:organization, :ce_enabled], type_name: 'ProjectsForEnrollment' }
    field :victim_service_provider, HmisSchema::Enums::Hud::NoYesMissing, null: false, default_value: 99
    field :description, String, null: true
    field :contact_information, String, null: true
    custom_data_elements_field
    access_field do
      define_method(:policy) { @policy ||= policy_for(object, policy_type: :hmis_organization) }

      bool_field(:can_delete_organization) { policy.can_delete? }
      bool_field(:can_edit_organization) { policy.can_edit? }
      bool_field(:can_create_projects) { policy.can_create_project? }
    end

    def projects(**args)
      resolve_projects(object.projects, **args)
    end

    def local_ce_match_rule_count
      access_denied! unless ce_match_rule_policy.can_manage?

      dataloader.with(Sources::CeMatchRuleOwnerCountSource, owner_type: Hmis::Hud::Organization.sti_name).load(object.id)
    end

    def effective_ce_match_rule_count
      access_denied! unless ce_match_rule_policy.can_manage?

      dataloader.with(Sources::CeMatchRuleEffectiveCountSource, owner_class: Hmis::Hud::Organization).load(object)
    end

    # Not for batch
    def effective_ce_match_rule_groups
      access_denied! unless ce_match_rule_policy.can_manage?

      rules_by_owner = effective_ce_match_rules.group_by { |rule| [rule.owner_type, rule.owner_id] }
      [
        ce_match_rule_group(owner: object.data_source, rules_by_owner: rules_by_owner, local: false),
        ce_match_rule_group(owner: object, rules_by_owner: rules_by_owner, local: true),
      ]
    end

    def self.organizations(scope = Hmis::Hud::Organization.all, user:)
      scope.viewable_by(user)
    end

    private

    def effective_ce_match_rules
      @effective_ce_match_rules ||= Hmis::Ce::Match::Rule.eligibility_and_priority_rules_for_entity(object)
    end

    def ce_match_rule_policy
      @ce_match_rule_policy ||= policy_for(Hmis::Ce::Match::Rule, policy_type: :ce_match_rule)
    end

    def ce_match_rule_group(owner:, rules_by_owner:, local:)
      OpenStruct.new(
        owner: owner,
        rules: rules_by_owner.fetch([owner.class.sti_name, owner.id], []),
        local: local,
      )
    end
  end
end
