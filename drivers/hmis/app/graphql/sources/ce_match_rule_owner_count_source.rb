# frozen_string_literal: true

module Sources
  class CeMatchRuleOwnerCountSource < GraphQL::Dataloader::Source
    def initialize(owner_type:)
      @owner_type = owner_type
    end

    def fetch(owner_ids)
      ordered_ids = owner_ids.map(&:to_i)
      counts = Hmis::Ce::Match::Rule.
        where(owner_type: @owner_type, owner_id: ordered_ids).
        group(:owner_id).
        count

      # GraphQL requires results to be returned in exactly the same order as requested
      ordered_ids.map { |id| counts[id] || 0 }
    end
  end
end
