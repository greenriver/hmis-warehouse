# frozen_string_literal: true

module Types
  module HmisSchema
    module HasCeMatchRules
      extend ActiveSupport::Concern

      included do
        field :effective_ce_match_rule_count, Integer, null: false, description: 'Number of CE match rules that apply to this record, including inherited rules.'
        field :local_ce_match_rule_count, Integer, null: false, description: 'Number of CE match rules owned directly by this record.'
        field :effective_ce_match_rule_groups, [HmisSchema::CeMatchRuleGroup], null: false, description: 'All CE match rules that apply to this record, including inherited rules, grouped by their owner.'
      end

      def local_ce_match_rule_count
        access_denied! unless ce_match_rule_policy.can_manage?

        dataloader.with(Sources::CeMatchRuleOwnerCountSource, owner_type: object.class.sti_name).load(object.id)
      end

      def effective_ce_match_rule_count
        access_denied! unless ce_match_rule_policy.can_manage?

        dataloader.with(Sources::CeMatchRuleEffectiveCountSource, owner_class: object.class).load(object)
      end

      # Not for batch. As a future improvement, we could reuse the data loader approach (see CeMatchRuleEffectiveCountSource)
      # but since this is only loaded on 1 org at a time, use the existing eligibility_and_priority_rules_for_entity helper.
      def effective_ce_match_rule_groups
        access_denied! unless ce_match_rule_policy.can_manage?

        rules_by_owner = Hmis::Ce::Match::Rule.eligibility_and_priority_rules_for_entity(object).
          group_by { |rule| [rule.owner_type, rule.owner_id] }

        ce_match_rule_group_owners.map do |owner|
          OpenStruct.new(
            owner: owner,
            rules: rules_by_owner.fetch([owner.class.sti_name, owner.id], []),
            local: owner == object,
          )
        end
      end

      private

      def ce_match_rule_group_owners
        # Implement in the including class
        raise NotImplementedError
      end

      def ce_match_rule_policy
        @ce_match_rule_policy ||= policy_for(Hmis::Ce::Match::Rule, policy_type: :ce_match_rule)
      end
    end
  end
end
