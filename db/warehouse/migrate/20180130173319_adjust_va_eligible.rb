class AdjustVaEligible < ActiveRecord::Migration[4.2]
  def change
    change_column :cohort_clients, :va_eligible, :string
  end
end
