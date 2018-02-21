class UpdateClaimsMetricsWithPaid < ActiveRecord::Migration
  def change
    tables = [
      :claims_top_conditions,
      :claims_top_ip_conditions,
      :claims_top_providers,
    ]
    tables.each do |table|
      add_column table, :baseline_paid, :float
      add_column table, :implementation_paid, :float
    end

    add_column :claims_ed_nyu_severity, :baseline_visits, :float
    add_column :claims_ed_nyu_severity, :implementation_visits, :float
  end
end
