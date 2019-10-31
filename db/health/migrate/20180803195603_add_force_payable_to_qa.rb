class AddForcePayableToQa < ActiveRecord::Migration[4.2]
  def change
    add_column :qualifying_activities, :force_payable, :boolean, default: false, null: false
  end
end
