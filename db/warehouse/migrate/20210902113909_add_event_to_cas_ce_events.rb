class AddEventToCasCeEvents < ActiveRecord::Migration[5.2]
  def change
    add_column :cas_referral_events, :event, :integer
  end
end
