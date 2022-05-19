class AdditionalPmClientColumns < ActiveRecord::Migration[6.1]
  def change
    [:reporting, :comparison].each do |variant_name|
      [
        :seen_in_range,
        :retention_or_positive_destination,
        :earned_income_stayer,
        :earned_income_leaver,
        :non_employment_income_stayer,
        :non_employment_income_leaver,
      ].each do |column|
        add_column :pm_clients, "#{variant_name}_#{column}", :boolean, default: false, null: false
      end
    end
  end
end
