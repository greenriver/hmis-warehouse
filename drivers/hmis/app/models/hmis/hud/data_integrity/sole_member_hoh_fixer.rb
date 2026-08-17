###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Promotes the only member of a household to Head of Household (RelationshipToHoH = 1).
# Does not change HouseholdID, multi-member households, blank HouseholdIDs, or existing HoHs.
#
# Scope-based usage (e.g. in an opt-in ImporterExtension):
# Hmis::Hud::DataIntegrity::SoleMemberHohFixer.run!(scope: staging_scope, conflict_target: [:id, :importer_log_id])
#
# Console convenience:
# Hmis::Hud::DataIntegrity::SoleMemberHohFixer.for_data_source!(data_source_id: ds_id)
#
class Hmis::Hud::DataIntegrity::SoleMemberHohFixer
  include ArelHelper

  BATCH_SIZE = 1_000

  # @param scope [ActiveRecord::Relation] the scope of Enrollment(-like) records to process.
  # @param conflict_target [Array] unique key columns for upsert. Defaults to [:id],
  #   but configurable so that callers working with partitioned tables can pass a compound key.
  # @return [Integer] number of records that were updated
  def self.run!(scope:, conflict_target: [:id])
    new(scope: scope, conflict_target: conflict_target).run!
  end

  # Convenience helper: run on all HMIS Enrollments in a data source.
  # @param data_source_id [Integer] restrict to HMIS Enrollments in this data source.
  # @return [Integer] number of records that were updated
  def self.for_data_source!(data_source_id:)
    run!(scope: Hmis::Hud::Enrollment.hmis.where(data_source_id: data_source_id))
  end

  def initialize(scope:, conflict_target: [:id])
    @scope = scope
    @model_class = scope.klass
    @conflict_target = conflict_target
  end

  # @return [Integer] number of records that were updated
  def run!
    total_updated = 0
    candidates.in_batches(of: BATCH_SIZE) do |batch|
      changed = batch.to_a
      next if changed.empty?

      changed.each do |record|
        record.RelationshipToHoH = 1
        # If this is a CSV importer staging record, recompute source_hash to keep it in sync.
        # The CSV importer uses this hash to detect changes between imports.
        record.set_source_hash if record.respond_to?(:set_source_hash)
      end
      persist!(changed)
      total_updated += changed.size
    end
    Rails.logger.info "Set HoH in #{total_updated} single-member households"
    total_updated
  end

  def candidates
    # Staging ImportConcern default-scopes with_deleted, so DateDeleted must be filtered explicitly.
    # Warehouse Enrollment scope already excludes them via paranoia.
    live_scope = @scope.where(DateDeleted: nil)

    # Use HUD column names (e.g. HouseholdID not household_id)
    # because importer staging tables do not alias snake_case.
    # Exclude nil and ''
    single_member_household_ids = live_scope.where.not(HouseholdID: [nil, '']).
      group(:HouseholdID).
      having(nf('COUNT', [:HouseholdID]).eq(1)).
      select(:HouseholdID)

    enrollments_scope = live_scope.where(HouseholdID: single_member_household_ids)

    # where.not(RelationshipToHoH: 1) alone skips nils, so explicitly include them
    rel = @model_class.arel_table[:RelationshipToHoH]
    enrollments_scope.where(rel.not_eq(1).or(rel.eq(nil)))
  end

  private

  def persist!(records)
    result = @model_class.import( # import skips PaperTrail and timestamps
      records,
      validate: false,
      timestamps: false,
      on_duplicate_key_update: {
        conflict_target: @conflict_target,
        columns: update_columns,
      },
    )
    raise "error: #{result.failed_instances.inspect}" if result.failed_instances.any?
  end

  def update_columns
    columns = [:RelationshipToHoH]

    # Only refresh source_hash on records that support it (versioned CSV importer staging records)
    columns << :source_hash if @model_class.column_names.include?('source_hash')

    columns
  end
end
