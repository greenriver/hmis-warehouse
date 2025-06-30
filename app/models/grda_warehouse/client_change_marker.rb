###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class GrdaWarehouse::ClientChangeMarker < GrdaWarehouseBase
  self.table_name = 'client_change_markers'

  # destination client
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'

  scope :dirty, -> { where(arel_table[:current_version].gt(arel_table[:processed_version])) }

  def self.mark_processed(marks)
    return if marks.empty?

    records = marks.map do |record|
      {
        client_id: record.client_id,
        current_version: 1, # not used but cannot be null
        processed_version: record.current_version,
      }
    end
    import!(
      records,
      validate: false,
      on_duplicate_key_update: {
        conflict_target: [:client_id],
        columns: [:processed_version],
      },
    )
  end

  def self.upsert_or_bump_version(client_ids:)
    return if client_ids.empty?

    records = client_ids.uniq.map do |client_id|
      {
        client_id: client_id,
        current_version: 1,
      }
    end
    import!(
      records,
      validate: false,
      on_duplicate_key_update: {
        conflict_target: [:client_id],
        columns: "current_version = #{table_name}.current_version + 1",
      },
    )
  end
end
