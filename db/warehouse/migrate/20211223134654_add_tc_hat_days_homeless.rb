class AddTcHatDaysHomeless < ActiveRecord::Migration[5.2]
  def change
    add_column :Client, :tc_hat_additional_days_homeless, :integer, default: 0
  end
end
