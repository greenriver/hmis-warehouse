class AdjustVaEligible < ActiveRecord::Migration
  def change
    change_column :cohort_clients, :va_eligible, :string
  end
end
