class AddHomelessDaysDetailsToPmClient < ActiveRecord::Migration[5.2]
  def change
    [:reporting, :comparison].each do |period|
      add_column :pm_clients, "#{period}_days_in_homeless_bed", :integer
      add_column :pm_clients, "#{period}_days_in_homeless_bed_details", :jsonb
      add_column :pm_clients, "#{period}_days_in_homeless_bed_in_period", :integer
      add_column :pm_clients, "#{period}_days_in_homeless_bed_details_in_period", :jsonb
    end
  end
end
