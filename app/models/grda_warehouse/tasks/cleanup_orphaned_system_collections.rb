###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Tasks
  # Finds system Collections (Collection.system, excluding must_exist aggregates
  # like "All Cohorts") that have zero live entities -- either they never had any,
  # or every entity they pointed to has since been deleted (hard or soft) -- and
  # destroys them along with their AccessControls and per-source UserGroups.
  class CleanupOrphanedSystemCollections
    include MaintenanceTaskInstrumentation

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    def run!
      # Dry runs shouldn't touch the shared maintenance-task/alerting state.
      return perform_cleanup if @dry_run

      result = nil

      instrument_as_maintenance_task do |run|
        result = perform_cleanup
        run.complete!
      end

      result
    end

    private def perform_cleanup
      candidates = build_candidates
      destroyed_ids = []
      failed = []

      candidates.each do |candidate|
        next if @dry_run

        begin
          candidate[:collection].destroy_with_associated_records!
          destroyed_ids << candidate[:id]
        rescue StandardError => e
          # One failure shouldn't abort the rest of the run.
          failed << { id: candidate[:id], error: e.message }
          Rails.logger.error("CleanupOrphanedSystemCollections: failed to destroy Collection##{candidate[:id]}: #{e.message}")
        end
      end

      Rails.logger.info("CleanupOrphanedSystemCollections: found #{candidates.length} candidates, destroyed #{destroyed_ids.length}, failed #{failed.length}, destroyed_ids: #{destroyed_ids.inspect}")

      if failed.any?
        Sentry.capture_exception_with_info(
          StandardError.new("CleanupOrphanedSystemCollections: #{failed.size} collection(s) failed to destroy"),
          info: { failed: failed },
        )
      end

      { candidates: candidates, destroyed_ids: destroyed_ids, failed: failed, dry_run: @dry_run }
    end

    private def build_candidates
      orphaned_collections.map do |collection|
        {
          id: collection.id,
          name: collection.name,
          collection_type: collection.collection_type,
          source_type: collection.source_type,
          source_id: collection.source_id,
          entity_rows_count: collection.group_viewable_entities.count,
          access_controls_count: collection.access_controls.count,
          collection: collection,
        }
      end
    end

    # Collection is primary DB; group_viewable_entities/:entity are warehouse DB.
    # Per-collection association access (no joins) keeps this cross-DB safe.
    private def orphaned_collections
      Collection.system.where(must_exist: false).select { |collection| orphaned?(collection) }
    end

    private def orphaned?(collection)
      gves = collection.group_viewable_entities.includes(:entity).load
      gves.none? { |gve| gve.entity.present? }
    rescue NameError
      # entity_type names a class that's been renamed or removed.
      Rails.logger.warn("CleanupOrphanedSystemCollections: unrecognized entity_type on Collection##{collection.id}, excluding")
      false
    end
  end
end
