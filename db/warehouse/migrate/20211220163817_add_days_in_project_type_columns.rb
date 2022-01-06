class AddDaysInProjectTypeColumns < ActiveRecord::Migration[5.2]
  def change
    [:reporting, :comparison].each do |period|
      [:es, :sh, :so, :th].each do |project_type|
        add_column :pm_clients, "#{period}_days_in_#{project_type}_bed", :integer
        add_column :pm_clients, "#{period}_days_in_#{project_type}_bed_details", :jsonb
        add_column :pm_clients, "#{period}_days_in_#{project_type}_bed_in_period", :integer
        add_column :pm_clients, "#{period}_days_in_#{project_type}_bed_details_in_period", :jsonb
      end
    end
  end
end
