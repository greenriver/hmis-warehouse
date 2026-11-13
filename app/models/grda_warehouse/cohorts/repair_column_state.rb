###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Cohorts
  # Cohort#column_state entries can carry a memoized @cohort_column ivar (a live
  # GrdaWarehouse::Cohorts::CohortColumn) that isn't on the column's permitted_classes allow-list.
  # Strips that ivar from affected rows and re-saves so column_state deserializes cleanly.
  class RepairColumnState
    BATCH_SIZE = 500

    def self.run!
      new.run!
    end

    def run!
      each_poisoned_row { |id, raw| repair_row(id, raw) }
    end

    private

    def each_poisoned_row
      last_id = 0
      loop do
        rows = GrdaWarehouse::Cohort.connection.select_rows(
          "SELECT id, column_state FROM cohorts WHERE id > #{last_id} ORDER BY id LIMIT #{BATCH_SIZE}",
        )
        break if rows.empty?

        rows.each do |(id, raw)|
          next if raw.blank?

          begin
            YAML.safe_load(raw, permitted_classes: permitted_classes, aliases: true)
          rescue Psych::DisallowedClass
            yield(id.to_i, raw)
          end
        end
        last_id = rows.last.first.to_i
      end
    end

    def repair_row(id, raw)
      column_state = YAML.unsafe_load(raw)
      column_state.each do |col|
        col.remove_instance_variable(:@cohort_column) if col.instance_variable_defined?(:@cohort_column)
      end
      GrdaWarehouse::Cohort.unscoped.select(:id).find(id).update_column(:column_state, column_state)
    rescue StandardError => e
      Rails.logger.error("GrdaWarehouse::Cohorts::RepairColumnState failed for cohort #{id}: #{e.message}")
    end

    def permitted_classes
      GrdaWarehouse::Cohorts::CohortColumn.known_cohort_columns.map(&:constantize)
    end
  end
end
