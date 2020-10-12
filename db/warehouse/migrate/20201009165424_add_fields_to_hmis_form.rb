class AddFieldsToHmisForm < ActiveRecord::Migration[5.2]
  def change
    add_column :hmis_assessments, :covid_19_impact_assessment, :boolean, default: false
    add_column :hmis_forms, :covid_impact_updated_at, :datetime
    add_column :hmis_forms, :number_of_bedrooms, :integer
    add_column :hmis_forms, :subsidy_months, :integer
    add_column :hmis_forms, :total_subsidy, :integer
    add_column :hmis_forms, :monthly_rent_total, :integer
    add_column :hmis_forms, :percent_ami, :integer
    add_column :hmis_forms, :household_type, :string
    add_column :hmis_forms, :household_size, :integer
  end
end
