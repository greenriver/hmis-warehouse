# frozen_string_literal: true

module Sources
  # Performantly resolves the count of directly-owned CE eligibility rules for the given owner.
  # For example, for a given project, this returns only the count of rules owned by *this* project.
  # Compare to CeMatchRuleEffectiveCountSource, which resolves a count of all rules
  # applicable to the owner, including inherited rules.
  class CeMatchRuleOwnerCountSource < GraphQL::Dataloader::Source
    def initialize(owner_type:)
      @owner_type = owner_type
    end

    def fetch(owner_ids)
      ordered_ids = owner_ids.map(&:to_i)
      # TODO(#9337) - incorporate priority rules in the count when they are added to the UI
      counts = Hmis::Ce::Match::Rule.eligibility_requirement.
        where(owner_type: @owner_type, owner_id: ordered_ids).
        group(:owner_id).
        count

      # GraphQL requires results to be returned in exactly the same order as requested
      ordered_ids.map { |id| counts[id] || 0 }
    end
  end
end
