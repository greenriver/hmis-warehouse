class CreateAccountableCareOrganizations < ActiveRecord::Migration
  def change
    create_table :accountable_care_organizations do |t|
      t.string :name
    end
  end
end
