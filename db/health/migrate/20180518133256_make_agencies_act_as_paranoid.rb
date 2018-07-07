class MakeAgenciesActAsParanoid < ActiveRecord::Migration
  def change
    add_timestamps :agencies
    add_column :agencies, :deleted_at, :datetime, index: true
  end
end
