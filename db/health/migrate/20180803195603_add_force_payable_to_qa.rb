class AddForcePayableToQa < ActiveRecord::Migration
  def change
    add_column :qualifying_activities, :force_payable, :boolean, default: false, null: false
  end
end
