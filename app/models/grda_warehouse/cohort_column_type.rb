# frozen_string_literal: true

module GrdaWarehouse
  class CohortColumnType < GrdaWarehouseBase
    validates :class_name, presence: true, uniqueness: true

    scope :active, -> { where(active: true) }

    def activate
      update(active: true)
    end

    def deactivate
      update(active: false)
      remove_from_cohorts
    end

    def remove_from_cohorts
      GrdaWarehouse::Cohort.all.each do |cohort|
        cohort.update!(column_state: cohort.column_state.reject { |col| col.column_type.class_name == class_name })
      end
    end
  end
end
