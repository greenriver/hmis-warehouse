class AddHousingStatusToYouthCaseManagement < ActiveRecord::Migration[4.2]
  def change
    add_column :youth_case_managements, :housing_status, :string
    add_column :youth_case_managements, :other_housing_status, :string
  end
end
