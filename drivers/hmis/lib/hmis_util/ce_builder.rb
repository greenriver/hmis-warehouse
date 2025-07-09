# frozen_string_literal: true

# place for storing utility methods that we need to run manually/locally until all CE configuration functionality is in place
module HmisUtil
  class CeBuilder
    # Run this after changing/adding/removing match expressions
    # Accepts optional GrdaWarehouse::Hud::Client scope
    def self.build_candidate_pools(clients: nil)
      # Build candidate pools
      opportunities = Hmis::Ce::Opportunity.active
      Hmis::Ce::Match::CandidatePoolBuilder.new(opportunities).perform

      # Delete orphaned pools (to clear out any misconfigured match expressions)
      Hmis::Ce::Match::CandidatePool.where.missing(:opportunities).find_each(&:destroy!)

      # Run the match engine for each candidate pool
      clients ||= GrdaWarehouse::Hud::Client.destination
      Hmis::Ce::Match::CandidatePool.all.each do |pool|
        Hmis::Ce::Match::Engine.call(pool, clients)
      end
    end
  end
end
