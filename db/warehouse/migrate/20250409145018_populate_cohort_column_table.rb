# frozen_string_literal: true

class PopulateCohortColumnTable < ActiveRecord::Migration[7.0]
  def up
    GrdaWarehouse::CohortColumnType.maintain!
  end

  def down
    GrdaWarehouse::CohortColumnType.destroy_all
  end
end
