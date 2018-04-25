class AddOriginalChronicToCohorts < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :original_chronic, :boolean, default: false, null: false
  end
end
