class AddNaturallyPayableToClaims < ActiveRecord::Migration
  def change
    add_column :qualifying_activities, :naturally_payable, :boolean, default: false, null: false
  end
end
