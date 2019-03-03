class AddHousingStatusToYouthCaseManagement < ActiveRecord::Migration
  def change
    add_column :youth_case_managements, :housing_status, :string
    add_column :youth_case_managements, :other_housing_status, :string
  end
end
