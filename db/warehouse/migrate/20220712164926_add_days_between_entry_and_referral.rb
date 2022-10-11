class AddDaysBetweenEntryAndReferral < ActiveRecord::Migration[6.1]
  def change
    add_column :ce_performance_clients, :days_between_entry_and_initial_referral, :integer
  end
end
