class AddShortNameForCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :short_name, :string
  end
end
