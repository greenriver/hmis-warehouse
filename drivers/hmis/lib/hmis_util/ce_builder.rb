# frozen_string_literal: true

# place for storing utility methods that we need to run manually/locally until all CE configuration functionality is in place
module HmisUtil
  class CeBuilder
    # convenience methods
    def self.build_candidate_pools(...) = new.build_candidate_pools(...)
    def self.rebuild_clients(...) = new.rebuild_clients(...)

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

    # Development utility
    # Run this after changing/adding/removing match expressions
    #
    # @param opportunities [ActiveRecord::Relation, nil] Optional opportunities scope to limit pool building
    # @param progress [Boolean] Whether to show progress during processing
    # @param cleanup_orphans [Boolean] Whether to immediately remove orphaned pools (development only)
    def build_candidate_pools(opportunities: nil, progress: false, cleanup_orphans: false, force_reprocessing: true)
      mark_pools_dirty_and_build(opportunities: opportunities, cleanup_orphans: cleanup_orphans, force_reprocessing: true)
      process_dirty_markers(progress: progress)
    end

    # Force rebuild for specific clients
    #
    # @param clients [ActiveRecord::Relation] Clients to mark as dirty and process
    # @param progress [Boolean] Whether to show progress during processing
    def rebuild_clients(clients:, progress: false)
      mark_clients_dirty(clients)
      process_dirty_markers(progress: progress)
    end

    private

    def mark_pools_dirty_and_build(opportunities:, cleanup_orphans: false, force_reprocessing: nil)
      Hmis::Ce::Match::CandidatePool.lock_for_maintenance do
        unit_group_ids = opportunities&.distinct&.pluck(:unit_group_id)&.compact
        Hmis::Ce::Match::CandidatePoolBuilder.new.perform(unit_group_ids: unit_group_ids, force_reprocessing: force_reprocessing)
      end

      # Optional immediate cleanup for development (production uses time-based cleanup)
      Hmis::Ce::Match::CandidatePool.orphaned.find_each(&:destroy!) if cleanup_orphans
    end

    def mark_clients_dirty(clients)
      return unless clients.present?

      Hmis::Ce::ChangeMarker.upsert_or_bump_version(
        'GrdaWarehouse::Hud::Client',
        trackable_ids: clients.pluck(:id),
      )
    end

    def process_dirty_markers(progress: false)
      hit_max_iterations = false
      10.times do
        break unless Hmis::Ce::ChangeMarker.dirty.exists?

        Hmis::Ce::ProcessChangesJob.new.perform(progress: progress)
        hit_max_iterations = Hmis::Ce::ChangeMarker.dirty.exists?
      end

      return unless hit_max_iterations

      Rails.logger.warn('CeBuilder processing reached maximum iterations (10). Dirty markers may not be fully processed.')
    end
  end
end
