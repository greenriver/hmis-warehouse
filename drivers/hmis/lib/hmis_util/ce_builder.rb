# frozen_string_literal: true

# place for storing utility methods that we need to run manually/locally until all CE configuration functionality is in place
module HmisUtil
  class CeBuilder
    # Development utility
    # Run this after changing/adding/removing match expressions
    #
    # @param clients [ActiveRecord::Relation, nil] Optional client scope to mark as dirty for processing.
    #   If provided, these clients will be marked dirty and processed along with any other dirty records.
    #   If nil, only processes existing dirty records.
    # @param opportunities [ActiveRecord::Relation, nil] Optional opportunities scope to limit pool building
    # @param progress [Boolean] Whether to show progress during processing
    # @param cleanup_orphans [Boolean] Whether to immediately remove orphaned pools (development only)
    def self.build_candidate_pools(clients: nil, opportunities: nil, progress: false, cleanup_orphans: false)
      # Build candidate pools using the production job
      # This creates/updates pools based on active opportunities and marks them as dirty
      Hmis::Ce::BuildCandidatePoolsJob.new.perform(opportunity_ids: opportunities&.pluck(:id))

      # Optional immediate cleanup for development (production uses time-based cleanup)
      Hmis::Ce::Match::CandidatePool.orphaned.find_each(&:destroy!) if cleanup_orphans

      if clients
        # Mark the specified clients as dirty so they get processed
        Hmis::Ce::ChangeMarker.upsert_or_bump_version(
          'GrdaWarehouse::Hud::Client',
          trackable_ids: clients.pluck(:id),
        )
      end

      # Process all dirty pools and clients using the production job
      # This populates the pools by calling the match engine with the same logic used in production
      Hmis::Ce::ProcessChangesJob.new.perform(progress: progress) while Hmis::Ce::ChangeMarker.dirty.exists?
    end

    # Run this to keep state machine statuses in sync with custom statuses
    def self.create_state_machine_custom_statuses(data_source)
      Hmis::Ce::Referral.state_machine_states.map do |state|
        status = Hmis::Ce::CustomReferralStatus.find_or_initialize_by(
          key: state.to_s,
          data_source: data_source,
        )
        label = case state.to_s
        when 'rejected' then 'Declined'
        else state.to_s.humanize.titleize
        end
        status.name = label
        status.save!
      end
    end
  end
end
