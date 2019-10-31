class AddShortNameForCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :short_name, :string
  end
end
