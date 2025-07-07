###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

#
# Hmis::Ce::ChangeMarker
#
# Tracks changes to CE-related records using a versioning system to enable efficient
# incremental processing. Each tracked record has a current_version that increments
# when changes occur, and a processed_version that tracks the last processed state.
#
# Records are considered "dirty" when current_version > processed_version.
#
# See ./README_FOR_CHANGE_MARKER.md
class Hmis::Ce::ChangeMarker < GrdaWarehouseBase
  self.table_name = 'hmis_ce_change_markers'

  # trackable may be a destination client or pool
  belongs_to :trackable, polymorphic: true

  scope :dirty, -> { where(arel_table[:current_version].gt(arel_table[:processed_version])) }
  scope :clients, -> { where(trackable_type: 'GrdaWarehouse::Hud::Client') }
  scope :pools, -> { where(trackable_type: 'Hmis::Ce::Match::CandidatePool') }

  scope :batch, ->(start_id:, limit:) { order(:trackable_id).where(trackable_id: start_id..).limit(limit) }

  # Updates processed_version to match current_version, marking records as clean
  def self.mark_processed(marks)
    return if marks.empty?

    records = marks.map do |mark|
      {
        trackable_id: mark.trackable_id,
        trackable_type: mark.trackable_type,
        current_version: 1, # not used but cannot be null
        processed_version: mark.current_version,
      }
    end
    import!(
      records,
      validate: false,
      on_duplicate_key_update: {
        conflict_target: [:trackable_id, :trackable_type],
        columns: [:processed_version],
      },
    )
  end

  # Creates new markers or increments current_version for existing ones
  def self.upsert_or_bump_version(trackable_type, trackable_ids:)
    raise ArgumentError, "Trackable type not supported \"#{trackable_type}\"" unless trackable_type.in?(['GrdaWarehouse::Hud::Client', 'Hmis::Ce::Match::CandidatePool'])
    return if trackable_ids.empty?

    records = trackable_ids.uniq.map do |trackable_id|
      {
        trackable_id: trackable_id,
        trackable_type: trackable_type,
        current_version: 1,
      }
    end
    import!(
      records,
      validate: false,
      on_duplicate_key_update: {
        conflict_target: [:trackable_id, :trackable_type],
        columns: "current_version = #{table_name}.current_version + 1",
      },
    )
  end
end
