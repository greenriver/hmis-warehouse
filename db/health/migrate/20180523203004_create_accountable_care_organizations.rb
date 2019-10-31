class CreateAccountableCareOrganizations < ActiveRecord::Migration[4.2]
  def change
    create_table :accountable_care_organizations do |t|
      t.string :name
    end
  end
end
