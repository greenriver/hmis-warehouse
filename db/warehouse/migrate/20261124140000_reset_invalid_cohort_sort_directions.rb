###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Cohort#default_sort_direction is now validated; reset stored values outside the allowed set.
class ResetInvalidCohortSortDirections < ActiveRecord::Migration[8.1]
  def up
    GrdaWarehouse::Cohort.with_deleted.
      where.not(default_sort_direction: [nil, '', 'asc', 'desc']).
      update_all(default_sort_direction: 'desc')
  end

  def down
  end
end
