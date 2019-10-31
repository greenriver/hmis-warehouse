class AddNaturallyPayableToClaims < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :qualifying_activities, :naturally_payable, :boolean, default: false, null: false
  end
end
