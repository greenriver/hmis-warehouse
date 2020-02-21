class AddImportedToYouth < ActiveRecord::Migration[5.2]
  def change
    add_column :youth_intakes, :imported, :boolean, default: false
    add_column :youth_referrals, :imported, :boolean, default: false
    add_column :youth_case_managements, :imported, :boolean, default: false
    add_column :direct_financial_assistances, :imported, :boolean, default: false
  end
end
