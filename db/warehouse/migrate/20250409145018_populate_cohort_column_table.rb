# frozen_string_literal: true

class PopulateCohortColumnTable < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
  end

  def down
    GrdaWarehouse::Cohorts::CohortColumn.destroy_all
  end
end
