class MakeAgenciesActAsParanoid < ActiveRecord::Migration[4.2]
  def change
    add_timestamps :agencies
    add_column :agencies, :deleted_at, :datetime, index: true
  end
end
